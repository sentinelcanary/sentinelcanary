_q_exports = [
    'error',
    'search',
    'record',
    'species',
    'canary_png',
    'about',
    'admin',
    'edit',
    'user',
    'reaper',
    ]

import sys

from quixote.errors import PublishError
from quixote.publish import get_publisher
from quixote.util import StaticFile

from canary.ui import about
from canary.ui import admin
from canary.ui import edit
from canary.ui import user
from canary.ui import species
from canary.ui import record_ui
from canary.ui.pages import _q_index, _q_exception_handler, not_found, reaper
from canary.ui.browse_ui import Browse
from canary.qx_utils import MyStaticFile, load_static_exports
from canary.ui.search import search


# this is only here (?) because i was tweaking the image for fun; should
# actually be made available by the load_static_exports call for images below
#canary_png = StaticFile('/home/dlc33/projects/sentinel/sentineltestsite/images/brynn_canaries.png')

def error (request):
    raise PublishError(public_msg = "Oops, an error occured.")


this_module = sys.modules[__name__]
css_files = load_static_exports('/home/dlc33/projects/sentinel/sentineltestsite/html',
                                '.css')
for file, path in css_files:
    _q_exports.append(file)
    setattr(this_module, file, StaticFile(path, cache_time=60))


record = record_ui

def _q_lookup (request, name=''):
    if name == 'search':
        return search(request)
    elif name == 'favicon.ico':
        return request.redirect('/images/favicon.ico')
    elif name == 'browse':
        return Browse(request)
    elif name == 'login':
        return request.redirect('/user/login')
    elif name == 'logout':
        return request.redirect('/user/logout')
    else:
        return not_found()
