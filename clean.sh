#! /bin/bash
#
# clean examples build with sample.sh
#
#
echo
echo "cleaning examples"
echo
examples=( simple editor calculator lady lorenz )
#
#
for example in "${examples[@]}"
do
	rm "$example"
done
gnatclean -Psample.gpr
rm code/*.ad?
echo
echo "cleaning completed !"
echo

