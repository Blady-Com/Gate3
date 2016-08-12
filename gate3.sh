#!/bin/sh

if [ $# -eq 0 ]; then
  echo "Usage: gate3.sh glade-file"
  exit 1
fi

echo Generating Ada files...

dir=`dirname $1`
file=`cd $dir; pwd`/`basename $1`
prj=$file
srcdir=.
psrcdir="the current directory"
pixdir="pixmaps"

# Copy any pixmap files from pixdir to srcdir

mkdir -p $dir/$srcdir

if [ -d $dir/$pixdir ]; then
   cp $dir/$pixdir/*xpm $dir/$srcdir > /dev/null 2>&1
fi

owd=`pwd`
cd $dir

if [ $? != 0 ]; then
  echo "Couldn't change to $dir, aborting."
  exit 1
fi

gt="gate3wd/$prj"
mkdir -p $gt > /dev/null 2>&1
tmp=$gt/tmp
/bin/rm -rf $tmp
mkdir $tmp
wd=`pwd`
`dirname $0`/gate3 -o $tmp $file -t `dirname $0`/../share/gate3/tmplt

if [ $? != 0 ]; then
  echo "Couldn't generate Ada code. Exiting."
  exit 1
fi

cd $tmp
files=`echo *.ada`
gnatchop $files
/bin/rm -f $files
files=`echo *`
cd $wd

if [ "True" = "True" ]; then
  conflicts=0
  echo "Merge of some changes failed. It usually means that some modified code
is obsolete in the current project file.
Conflicts have been kept in the following files to help merging manually:
" > $gt/conflicts.txt

  for j in $files; do
    if [ -f $j ]; then
      /usr/bin/merge $j $gt/$j $tmp/$j 2>/dev/null
    else
      cp $tmp/$j $j
    fi

    if [ $? = 1 ]; then
      conflicts=1
      echo "$j" >> $gt/conflicts.txt
    fi
  done

  echo "The following files have been created/updated in $psrcdir:"

  for j in $files; do
    echo "  "$j
  done

  if [ $conflicts = 1 ]; then
    cat $gt/conflicts.txt
  fi

  echo done.

else

  /bin/rm -f $gt/gate.difs

  for j in $files; do
    /usr/bin/diff -u $gt/$j $j >> $gt/gate.difs 2>/dev/null
  done

  /bin/cp -f $tmp/* .
  /bin/rm -f *.rej *.orig

  if cat $gt/gate.difs | /usr/bin/patch -f > $gt/patch.out 2>&1; then
    echo "The following files have been created/updated in $psrcdir:"

    for j in $files; do
      echo "  "$j
    done

    /bin/rm -f *.orig
  else
    echo "The following files have been updated in $psrcdir:"

    for j in $files; do
      echo "  "$j
    done

    cat << EOF
Merge of some changes failed. It usually means that some modified code
is obsolete in the current project file.
.rej files have been generated to help merging manually if needed.
EOF
  fi

  echo done.
fi

/bin/mv -f $tmp/* $gt/
