# script instructions is rather inside of booktools/bookgen.sh
# forked and repurposed from BibleNLP/ebible repo. currently uses litte other than\
# the corpus and indices of that repo. havent deleted anything from it though

# glob sanitization handled by set -f. cursorily no other uses of file matching 
# used, so set -f set globally

# only 181 books have book name candidates identified from danny023/Refined-Holy-Bible-XML
# none which have registered relationship with the translations themself
# I suspect a LLM translated them.

# because of words like:
16 fellow-disciples
16 lovingkindnesses
16 unprofitableness
17 Abel-beth-maachah
17 Chephar-haammonai
17 Kibroth-hattaavah
17 Sela-hammahlekoth
17 covenant-breakers
18 Bashan-havoth-jair
18 Chushan-rishathaim
21 Maher-shalal-hash-baz

# in the kjv as an example, setting the font size too large also creates a situation
# where the word is bigger than the possible allocation, and finds an exception.
# this script purposefully(?) avoids hyphenation, the hyphen-library method of hyphenation
# seems to require an industry scale implementation. personally handling hyphenation was
# interesting when dealing with tabs, but between the trifle, unnecessariness, and difficulty...rather Lord willing
# perhaps handling already hyphenated words
