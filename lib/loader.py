import email
import re
import time
import traceback

import dtuple

from quixote import enable_ptl
enable_ptl()

from canary.source_catalog import Source
from canary.utils import DTable

class Queue:

    def __init__ (self):
        self.batches = []

    def load (self, cursor):
        cursor.execute("""
                       SELECT *
                       FROM queued_batches
                       ORDER BY date_added
                       """)
        fields = [d[0] for d in cursor.description]
        desc = dtuple.TupleDescriptor([[f] for f in fields])
        rows = cursor.fetchall()
        for row in rows:
            row = dtuple.DatabaseTuple(desc, row)
            # FIXME: reconcile this with class Batch()
            batch = {}
            for field in fields:
                #print 'setting batch["%s"] to %s' % (field, row[field])
                batch[field] = row[field]
            self.batches.append(batch)


class QueuedRecord (DTable):

    STATUS_UNCLAIMED = 0
    STATUS_CLAIMED = 1
    STATUS_FINISHED = 2

    def __init__ (self):
        self.uid = -1
        self.queued_batch_id = -1
        self.user_id = ''
        self.status = self.STATUS_UNCLAIMED
        self.title = ''
        self.source = ''


    def load (self, cursor):
        """
        Load a batch's queued records.
        """
        cursor.execute("""
                       SELECT status, queued_batch_id, user_id, title, source
                       FROM queued_records
                       WHERE uid = %s
                       """, int(self.uid))
        fields = [d[0] for d in cursor.description]
        desc = dtuple.TupleDescriptor([[f] for f in fields])
        row = cursor.fetchone()
        row = dtuple.DatabaseTuple(desc, row)
        for field in fields:
            self.set(field, row[field])


    def save (self, cursor):
        
        if self.uid == -1:
            print 'inserting new queued_record'
            cursor.execute("""
                           INSERT INTO queued_records
                           (uid, queued_batch_id, status, 
                           user_id, title, source)
                           VALUES (NULL, %s, %s, 
                           %s, %s, %s, %s)
                           """, (self.queued_batch_id, self.status, 
                           self.user_id, self.title, self.source)
                           )
            self.uid = self.get_new_uid(cursor)

        else:
            print 'updating queued_record'
            cursor.execute("""
                           UPDATE queued_records
                           SET queued_batch_id = %s, status = %s, 
                           user_id = %s, title = %s, source = %s
                           WHERE uid = %s
                           """, (self.queued_batch_id, self.status, 
                           self.user_id, self.title, self.source,
                           self.uid)
                           )
        # FIXME: should this be set from the SQL?
        self.date_modified = time.strftime(str('%Y-%m-%d'))


class Batch:

    # FIXME: init shouldn't need a damn cursor, write a load() function
    def __init__ (self, file_name=None, source_uid=-1):
        self.uid = -1
        self.file_name = file_name
        self.source_uid = source_uid
        self.num_records = -1
        self.queued_records = {}


    def load (self, cursor):
        """
        Load a batch's queued records.
        """
        cursor.execute("""
                       SELECT uid, status, user_id, title, source
                       FROM queued_records
                       WHERE queued_batch_id = %s
                       ORDER BY status
                       """, int(self.uid))
        fields = [d[0] for d in cursor.description]
        desc = dtuple.TupleDescriptor([[f] for f in fields])
        rows = cursor.fetchall()
        for row in rows:
            row = dtuple.DatabaseTuple(desc, row)
            record = QueuedRecord()
            for field in fields:
                record.set(field, row[field])
            self.queued_records[record.uid] = record


    def save (self, cursor):
        if self.uid == -1:
            cursor.execute("""
                           INSERT INTO queued_batches
                           (uid, file_name, source_uid, num_records, date_added)
                           VALUES
                           (NULL, %s, %s, %s, CURDATE())
                           """, (self.file_name, self.source_uid, self.num_records)
                           )
            cursor.execute("""
                           SELECT LAST_INSERT_ID() AS new_uid
                           """)
            row = cursor.fetchone()
            self.uid = row[0]
            self.date_added = time.strftime(str('%Y-%m-%d'))

        else:
            cursor.execute("""
                           UPDATE queued_batches
                           SET file_name = %s,
                           num_records = %s
                           WHERE uid = %s
                           """, (self.file_name, self.num_records, self.uid)
                           )
        
        # save the records
        for record_id in self.queued_records.keys():
            record = self.queued_records[record_id]
            record.save(cursor)


    def add_records (self, cursor, records):
    
        for record in records:
            self.queued_records[record.id] = record




class Parser:

    def __init__ (self, source):
        self.re_result_sep = re.compile(source.re_result_sep)
        self.re_term_token = re.compile(source.re_term_token)


    def load (self, file_name):
        file = open(file_name)
        msg = email.message_from_file(file)
        file.close()

        records = []
        title = ''
        source = ''
        value = ''
        current_token = ''
        lines = msg.get_payload().split('\n')
        for line in lines:
            if self.re_result_sep.match(line):
                if not title == '' and not source == '':
                    records.append((title, source))
                    #print 'added %s: %s (%s)' % (len(records), title, source)
                    title = ''
                    source = ''
                else:
                    # reading first record
                    pass
            else:
                match = self.re_term_token.match(line)
                if match:
                    # Note: match.group(0) == line  (damn that snake!)
                    token = match.group(1)
                    value = match.group(2)
                    current_token = token
                    if token == 'TI':
                        title = value
                    elif token == 'SO':
                        source = value
                    else:
                        pass
                    #term = source.get_term_from_token(field_token)
                else:
                    if not line.strip() == '':
                        value = value + ' ' + line.strip()
                        if current_token == 'TI':
                            title = value
                        elif current_token == 'SO':
                            source = value
                    else:
                        # blank line
                        pass
        # Note: we don't catch the last record in the loop above,
        # so do it 'manually' here
        if not title == '' and not source == '':
            records.append((title, source))
        return records


if __name__ == '__main__':

    source = Source()
    source.re_result_sep = '^<.*>'
    source.re_term_token = '^([A-Z][A-Z]+) +-[ ](.*)'

    parser = Parser(source)
    records = parser.load('/home/dlc33/projects/sentinel/record_parser/test-data/ovid-medline-12.txt')
    print len(records), 'records:'
    print records

