========================================================================
tokenization-This means that spaces have to be inserted between (e.g.) words and punctuation.
=========================================================================

~/mosesSMT/mosesdecoder/scripts/tokenizer/tokenizer.perl -l en \
    < ~/mosesSMT/Baseline/corpus/training/src_eng.txt    \
    > ~/mosesSMT/Baseline/corpus/src_eng.txt.tok.en

~/mosesSMT/mosesdecoder/scripts/tokenizer/tokenizer.perl -l en \
    < ~/mosesSMT/Baseline/corpus/training/tgt_swa.txt    \
    > ~/mosesSMT/Baseline/corpus/tgt_swa.txt.tok.sw
==================================================================================
truecasing: The initial words in each sentence are converted to their most probable casing. This helps reduce data sparsity.
=======================================================================================

The truecaser first requires training, in order to extract some statistics about the text:
=============================================================================================

~/mosesSMT/mosesdecoder/scripts/recaser/train-truecaser.perl \
     --model ~/mosesSMT/Baseline/corpus/truecase-model.en --corpus     \
     ~/mosesSMT/Baseline/corpus/src_eng.txt.tok.en


~/mosesSMT/mosesdecoder/scripts/recaser/train-truecaser.perl \
     --model ~/mosesSMT/Baseline/corpus/truecase-model.sw --corpus     \
     ~/mosesSMT/Baseline/corpus/tgt_swa.txt.tok.sw

=======================================================================================
Truecasing uses another script from the Moses distribution:
========================================================================================

 ~/mosesSMT/mosesdecoder/scripts/recaser/truecase.perl \
   --model ~/mosesSMT/Baseline/corpus/truecase-model.en         \
   < ~/mosesSMT/Baseline/corpus/src_eng.txt.tok.en \
   > ~/mosesSMT/Baseline/corpus/training-data.txt.tok.en-sw.true.en


 ~/mosesSMT/mosesdecoder/scripts/recaser/truecase.perl \
   --model ~/mosesSMT/Baseline/corpus/truecase-model.sw         \
   < ~/mosesSMT/Baseline/corpus/tgt_swa.txt.tok.sw \
   > ~/mosesSMT/Baseline/corpus/training-data.txt.tok.en-sw.true.sw

============================================================================================
cleaning- Long sentences and empty sentences are removed as they can cause problems with the training pipeline, and obviously mis-aligned sentences are removed.
===================================================================================================================
Finally we clean, limiting sentence length to 80:
========================================

~/mosesSMT/mosesdecoder/scripts/training/clean-corpus-n.perl \
    ~/mosesSMT/Baseline/corpus/training-data.txt.tok.en-sw.true en sw \
    ~/mosesSMT/Baseline/corpus/training-data.txt.tok.en-sw.clean 1 80


========================================================================================================================
Language Model Training-used to ensure fluent output, so it is built with the target language
=========================================================================================================================

~/mosesSMT/mosesdecoder/bin/lmplz -o 3 <~/mosesSMT/Baseline/corpus/training-data.txt.tok.en-sw.true.sw > training-data.txt.en-sw.arpa.sw

============================================================================================================================
binarise (for faster loading) the *.arpa.en file using KenLM
=============================================================================================================================

 ~/mosesSMT/mosesdecoder/bin/build_binary \
   training-data.txt.en-sw.arpa.sw \
   training-data.txt.en-sw.blm.sw

===============================================================================================================
eck the language model by querying it
==============================================================================================================

echo "huu ni maandishi ya swahili ?"                       \
   | ~/mosesSMT/mosesdecoder/bin/query training-data.txt.en-sw.blm.sw

===================================================================================================================
Training the Translation System
===================================================================================================================

nohup nice ~/mosesSMT/mosesdecoder/scripts/training/train-model.perl -root-dir train \
 -corpus ~/mosesSMT/Baseline/corpus/training-data.txt.tok.en-sw.clean                             \
 -f en -e sw -alignment grow-diag-final-and -reordering msd-bidirectional-fe \
 -lm 0:3:$HOME/mosesSMT/Baseline/lm/training-data.txt.en-sw.blm.sw:8                          \
 -external-bin-dir ~/mosesSMT/mosesdecoder/tools >& training.out &

=============================================================================================================================
Tuning-requires a small amount of parallel data, separate from the training data.
=============================================================================================================================

cd ~/corpus
====================
 ~/mosesSMT/mosesdecoder/scripts/tokenizer/tokenizer.perl -l en \
   < dev/data-test.en > data-test.tok.en

 ~/mosesSMT/mosesdecoder/scripts/tokenizer/tokenizer.perl -l en \
   < dev/data-test.sw > data-test.tok.sw

 ~/mosesSMT/mosesdecoder/scripts/recaser/truecase.perl --model truecase-model.en \
   < data-test.tok.en > data-test.true.en

 ~/mosesSMT/mosesdecoder/scripts/recaser/truecase.perl --model truecase-model.sw \
   < data-test.tok.sw > data-test.true.sw

=============================================================================================================================
tuning process
==============
cd ~/working

 nohup nice ~/mosesSMT/mosesdecoder/scripts/training/mert-moses.pl \
  ~/mosesSMT/Baseline/corpus/data-test.true.en ~/mosesSMT/Baseline/corpus/data-test.true.sw \
  ~/mosesSMT/mosesdecoder/bin/moses train/model/moses.ini --mertdir ~/mosesSMT/mosesdecoder/bin/ \
  &> mert.out &

===========================================================================================================================
Testing-
======================================================================================================================
 ~/mosesSMT/mosesdecoder/bin/moses -f ~/mosesSMT/Baseline/working/mert-work/moses.ini

==========================================================================================================================
In order to make it start quickly, we can binarise the phrase-table and lexicalised reordering models.
=========================================================================================================================
~/mosesSMT/mosesdecoder/bin/processPhraseTableMin \
   -in train/model/phrase-table.gz -nscores 4 \
   -out binarised-model/phrase-table
 ~/mosesSMT/mosesdecoder/bin/processLexicalTableMin \
   -in train/model/reordering-table.wbe-msd-bidirectional-fe.gz \
   -out binarised-model/reordering-table

====================================================================
 ~/mosesSMT/mosesdecoder/bin/moses -f ~/mosesSMT/Baseline/working/binarised-model/moses.ini
====================================================================
nohup nice ~/mosesSMT/mosesdecoder/scripts/ems/experiment.perl -config config -exec &> log &
