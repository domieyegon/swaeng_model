#!/usr/bin/env bash
cd /home/d0mie/mosesSMT/Baseline/working/mert-work
/home/d0mie/mosesSMT/mosesdecoder/bin/extractor --sctype BLEU --scconfig case:true  --scfile run7.scores.dat --ffile run7.features.dat -r /home/d0mie/mosesSMT/Baseline/corpus/data-test.true.sw -n run7.best100.out.gz
