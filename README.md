#!/usr/bin/env bash

# forked and repurposed from BibleNLP/ebible repo. currently uses litte other than\
# the corpus and indices of that repo. havent deleted anything from it though

# dan1931 has * characters, which can possibly match glob patterns in strings
# brings to bear possible other sanitization issues like ~, maybe shopt solution

# only 181 books have book name candidates identified from danny023/Refined-Holy-Bible-XML
# none which have registered relationship with the translations themself
# I suspect a LLM translated them.


