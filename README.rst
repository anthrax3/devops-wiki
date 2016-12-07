devops-wiki
***********

Source for: http://wiki.devops.ge

Dev Machine
===========

#. Build sphinx image: ``make build-sphinx``
#. Run sphinx container: ``make dev``. Current directory is mounted as a
   volume, and is watched for changes to regenerate html pages automatically.
#. Wiki should be accessible at http://localhost:8080
#. After adding new topic/page run commit tests: ``make -i test``

Tests
=====

Spelling
--------

Checks all rst files spelling and reports incorrect words.
Output saved in: ``.build/spelling/output.txt``

.. sourcecode:: sh

  make TARGET="spelling" sphinxrun

To grep new words only: ``make new-words``.
What I usually do: ``make new-words >> spelling_wordlist.txt`` and than remove
wrong words from ``spelling_wordlist.txt``

Linkcheck
---------

Checks all links in rst files.
Output saved in: ``.build/linkcheck/output.txt``

.. sourcecode:: sh

  make TARGET="linkcheck" sphinxrun

Linecheck
---------

Greps lines with more than 80 chars.
Output saved in: ``.build/linecheck/output.txt``

.. sourcecode:: sh

  make TARGET="linecheck" sphinxrun

