#!/usr/bin/env bash
# 参考サイト: http://tukaikta.blog135.fc2.com/blog-entry-224.html

# ================各種設定================
# GNU 日本語MAN FREEBSD日本語MANのバージョン
export GNUJMAN_VER=20160815
export BSDJMAN_VER=10.3.20160430

#ダウンロードするファイル (GNU 日本語man)
#
# http://linuxjm.sourceforge.jp/ からダウンロードするファイルを指定します。
#export GNUJMAN=man-pages-ja-20120915.tar.gz
#export GNUJMAN=man-pages-ja-20150315.tar.gz
export GNUJMAN=man-pages-ja-$GNUJMAN_VER.tar.gz

# ダウンロードするファイル (BSD 日本語man)
#
# http://home.jp.freebsd.org/~kogane/ からダウンロードするファイルを指定します。
#export BSDJMAN_URLPATH=JMAN9/ja-man-doc-9.0.20120115.tbz
#export BSDJMAN_URLPATH=JMAN10/ja-man-doc-10.0.20140121.tbz
# export BSDJMAN_URLPATH=

# ftp://ftp.koganemaru.co.jp/pub/jmanc/ja-man-doc-11.0.20160729.64.txz
export BSDJMAN_URLPATH=pub/jmani10/ja-man-doc-$BSDJMAN_VER.64.txz

echo $GNUJMAN
echo $BSDJMAN_URLPATH

# ダウンロード場所
export DLPATH=~/Downloads

# インストール場所
#
# 日本語manページの検索優先順位は
# /usr/local/share/man/ja_JP.UTF-8 > /usr/local/share/man/ja
# となります。
# 初期設定では、まずGNUのmanが検索され、そこになければBSDのmanが検索されます。
#export GNUJMAN_PREFIX=/usr/local/share/man/ja_JP.UTF-8
export GNUJMAN_DIR=/usr/local/Cellar/man-pages-ja
export GNUJMAN_PREFIX=$GNUJMAN_DIR/$GNUJMAN_VER/share/man/ja
#export BSDMAN_PREFIX=/usr/local/share/man/ja
export BSDMAN_DIR=/usr/local/Cellar/ja-man-doc
export BSDMAN_PREFIX=$BSDMAN_DIR/$BSDJMAN_VER/share/man/ja

# localman_ja の場所
export LOCALMAN_JA_DIR=/usr/local/share/man/ja

# gプレフィックス付加の有無
#
# brew install coreutils などで GNUのコマンドをgプレフィックス付きでインストールしている人向け
#   例: gls, gmv など
# gプレフィックスを付けずにインストールしている場合は以下をfalseにしてください。
export G_PREFIX='true'  # (true|false)

# ========================================


function err_and_exit() {
    echo -e "ERROR: $@\nexsiting..."
    exit 1
}

# check already installed
if [ "$(ls -1 /usr/local/share/man/ja_JP.UTF-8/man1/ 2>/dev/null | wc -l)" -gt "200" -a "$(ls -1 /usr/local/share/man/ja/man1/ 2>/dev/null | wc -l)" -gt "200" ]; then
    echo -e "jams is already installed\nexsiting..."
    exit 0
fi

echo "日本語manualをインストールします。"

# install require packages
if ! which brew >/dev/null; then
    echo 'Homebrew is not installed'
    err_and_exit "status: $?"
fi
echo "Homebrew で groff をインストールします。"
brew tap homebrew/dupes 2>/dev/null && \
brew install groff  2>/dev/null && \

# edit /etc/man.conf
if ! grep '^JNROFF /usr/local/bin/groff' /etc/man.conf >/dev/null; then
    echo "/etc/man.conf を編集します。(オリジナルは /etc/man.conf.orig としてバックアップ)"
    sudo sed -i.orig \
    -e 's,^JNROFF[ '$'\t'']*/usr/bin/groff -Tnippon -mandocj -c$,JNROFF /usr/local/bin/groff -M /usr/share/groff/1.19.2/tmac -mtty-char -Dutf8 -Tutf8 -mandoc -mja -E,' \
    -e 's,^PAGER[ '$'\t'']*/usr/bin/less -is$,PAGER /usr/bin/less -isr,' \
    -e 's,^BROWSER[ '$'\t'']*/usr/bin/less -is$,BROWSER /usr/bin/less -isr,' \
    /etc/man.conf && \
    grep '^JNROFF[ '$'\t'']*/usr/local/bin/groff' /etc/man.conf >/dev/null || err_and_exit "status: $?"
    grep '^PAGER[ '$'\t'']*/usr/bin/less -isr' /etc/man.conf >/dev/null || err_and_exit "status: $?"
    grep '^BROWSER[ '$'\t'']*/usr/bin/less -isr' /etc/man.conf >/dev/null || err_and_exit "status: $?"
fi


## GNU JMAN
echo
echo 'JM Project の man-pages-ja（GNU、Linux）をインストールします．[Y/n]' && read ANS
if ! echo "$ANS" | grep '^[Nn]' >/dev/null; then
    #元のリンクを消す
    cd $LOCALMAN_JA_DIR
    for c in man{1..9}
    do
      cd $c
      for x in `ls`
      do
        if ls -l $x | grep -qF "Cellar/man-pages-ja" > /dev/null
        then
	      rm $x
	    fi
      done
      cd ..
    done
    rm -rf $GNUJMAN_DIR

    cd $DLPATH
    # man-pages-jaをダウンロード
    #mkdir $DLPATH/${GNUJMAN%%.*} && \
    #cd $DLPATH/${GNUJMAN%%.*} || err_and_exit
    if [ ! -e $DLPATH/$GNUJMAN ]; then
        curl https://linuxjm.osdn.jp/$GNUJMAN -o $DLPATH/$GNUJMAN
    fi
    test -e $DLPATH/$GNUJMAN || err_and_exit

    # 落としたファイルを解凍
    #gzip -dc $DLPATH/$GNUJMAN | tar xvf - || err_and_exit
    tar xvf $DLPATH/$GNUJMAN || err_and_exit "status: $?"

    # 解凍したフォルダの中に移動
    #mkdir $DLPATH/${GNUJMAN%%.*} && \
    test -d $DLPATH/${GNUJMAN%%.*}/script && cd $DLPATH/${GNUJMAN%%.*} || err_and_exit "status: $?"

    # pkgs.list を修正
    # TODO: 修正したいやつを指定できるオプション作る
    sed -i '' -e 's,Y$,N,' script/pkgs.list
    for i in GNU_coreutils GNU_bash GNU_binutils GNU_ed GNU_findutils GNU_gawk GNU_gcc GNU_gdb GNU_gdbm GNU_grep GNU_groff GNU_gzip GNU_indent GNU_less GNU_patch GNU_rcs GNU_screen GNU_sed GNU_tar GNU_texinfo bind byacc cdparanoia expect fetchmail logrotate mpg123 ncftp rdate rpm rssh rsync smartmontools tcpdump tcsh uudeview vsftpd ; do
        sed -i '' -e "s,^$i.*[YN]$,$i"$'\t'"Y," script/pkgs.list
    done && \

    # make config スクリプトを修正
    i=0
    while ! cp -n script/configure.perl script/configure.perl.bak${i}; do
        i=$(( $i + 1 ))
    done && \
    sed -i '' \
    -e 's,use Env qw (PATH LANG);,use Env qw (PATH LANG GNUJMAN_PREFIX);,' \
    -e 's,$MANROOT = "/usr/share/man/$LANG";,$MANROOT = "$GNUJMAN_PREFIX";,' \
    -e 's,if  ($ans eq "") {$ans = 0;},if  ($ans eq "") {$ans = 1;},' \
    -e 's,$OWNER = "root";,$OWNER = \"'"$USER"'\";,' \
    -e 's,$GROUP = "root";,$GROUP = "admin";,' \
    -e 's,\^\[yYcC\]/,^[yYcC]|^$/,' \
    -e 's,\[yYnNcCrR\]/,[yYnNcCrR]|^$/,' \
    -e 's,\[yYnNcCrR\]\.\*/,[yYnNcCrR].*|^$/,' \
    script/configure.perl && \

    # make を実行 (常にEnterを入力)
    yes '' | make config && \
    make install || err_and_exit
  # coreutilsの g プレフィックスのためにファイル名修正
  # gプレフィックスを付けずにインストールしている場合は
  if [[ "$G_PREFIX" == "true" ]]; then
      cd $GNUJMAN_PREFIX/man1
      #brew list coreutils | grep '/bin/' | grep -o 'g.*$' | sed -e 's,^g,,' -e 's,$,.1.gz,' | xargs -I% mv % g%
      for i in '[' base64 basename cat chcon chgrp chmod chown chroot cksum comm cp csplit cut date dd df dir dircolors dirname du echo env expand expr factor false fmt fold groups head hostid id install join kill link ln logname ls md5sum mkdir mkfifo mknod mktemp mv nice nl nohup nproc numfmt od paste pathchk pinky pr printenv printf ptx pwd readlink realpath rm rmdir runcon seq sha1sum sha224sum sha256sum sha384sum sha512sum shred shuf sleep sort split stat stdbuf stty sum sync tac tail tee test timeout touch tr true truncate tsort tty uname unexpand uniq unlink uptime users vdir wc who whoami yes  find locate oldfind updatedb xargs  grep egrep fgrep  dbus dbus-codegen perl resource settings tester tester-report view vim vimdiff vimex; do
          mv "${i}.1.gz" "g${i}.1.gz"  # || err_and_exit "status: $?: $i cannot rename to g${i}."
      done
  fi

  # /usr/local/share/man にリンク
    cd $LOCALMAN_JA_DIR
    for c in man{1..9}
    do
      cd $c
      for x in `ls ../../../../Cellar/man-pages-ja/$GNUJMAN_VER/share/man/ja/$c`
      do
          ln -sf ../../../../Cellar/man-pages-ja/$GNUJMAN_VER/share/man/ja/$c/$x .
      done
      cd ..
    done



fi


## BSD JMAN
echo 'FreeBSD の日本語manページ集 ja-man-doc をインストールします．[Y/n]' && read ANS
if ! echo "$ANS" | grep '^[Nn]' >/dev/null; then
    #元のリンクを消す
    cd $LOCALMAN_JA_DIR
    for c in man{1..9}
    do
      cd $c
      for x in `ls`
      do
        if ls -l $x | grep -qF "Cellar/ja-man-doc" > /dev/null
        then
          rm $x
        fi
      done
      cd ..
    done
    rm -rf $BSDMAN_DIR
    # ダウンロードするファイル名
    # $BSDJMAN_URLPATH から自動で設定されます
    export BSDJMAN=${BSDJMAN_URLPATH##*/}

    # ja-man-docをDL
    cd $DLPATH && \
    test -e $DLPATH/$BSDJMAN || \
    curl ftp://ftp.koganemaru.co.jp/$BSDJMAN_URLPATH -o $DLPATH/$BSDJMAN && \
    test -e $DLPATH/$BSDJMAN || err_and_exit

    # DLしたファイルを解凍
    mkdir -p $DLPATH/${BSDJMAN%.*}
    cd $DLPATH/${BSDJMAN%.*}
    #test -d $DLPATH/${BSDJMAN%.*}/usr/share/man || \
    #bzip2 -dc $DLPATH/$BSDJMAN | tar xf - || true
    tar xf $DLPATH/$BSDJMAN 2>/dev/null  # return not 0 due to extracting bad symlink

    # share/man/に移動
    cd $DLPATH/${BSDJMAN%.*}/usr/share/man || err_and_exit

    # gzipで圧縮されてるので解凍
    find ja -name "*.[0-9].gz" -type f -exec gunzip -fr  {} \;
    # gunzip -fr ./*  # return status is 1 due to unknown suffix

    # UTF-8に変換
    find ja -name "*.[0-9]" -exec nkf --overwrite -w {} \;

    # gzipに圧縮
    find ja -name '*.[0-9]' -exec gzip {} \;

    # manページを移動
    mkdir -p $BSDMAN_PREFIX && \
    rsync -rltD ./ja/ $BSDMAN_PREFIX || err_and_exit "status: $?"

  # /usr/local/share/man にリンク
    cd $LOCALMAN_JA_DIR
    for c in man{1..9}
    do
      cd $c
      for x in `ls ../../../../Cellar/ja-man-doc/$BSDJMAN_VER/share/man/ja/$c`
      do
          ln -sf ../../../../Cellar/ja-man-doc/$BSDJMAN_VER/share/man/ja/$c/$x .
      done
      cd ..
    done




fi




echo 'install successfully finished'
echo '以下のような設定を .bashrc や .zshrc などに書いておくと便利です。'
echo
echo "# man コマンド名 で英語manualを表示"
echo "alias man='env LANG=C man'"
echo "# jman コマンドで 日本語manualを表示"
echo "alias jman='env LANG=ja_JP.UTF-8 man'"
echo
