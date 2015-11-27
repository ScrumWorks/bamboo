#!/bin/bash
set -e
set -u
name=bamboo
version=${_BAMBOO_VERSION:-"1.0.5"}
description="Bamboo is a DNS based HAProxy auto configuration and auto service discovery for Mesos Marathon."
url="https://github.com/QuBitProducts/bamboo"
arch="all"
section="misc"
license="Apache Software License 2.0"
package_version=${_BAMBOO_PKGVERSION:-"-1"}
origdir="$(pwd)"
workspace="builder"
pkgtype="rpm"
builddir="build"
installdir="opt"
outputdir="output"
function cleanup() {
    cd ${origdir}/${workspace}
    rm -rf ${name}*.{deb,rpm}
    rm -rf ${builddir}
}

function bootstrap() {
    cd ${origdir}/${workspace}

    # configuration directory
    mkdir -p ${builddir}/${name}/${installdir}/bamboo/config

    pushd ${builddir}
}

function build() {

    # Prepare binary at /opt/bamboo/bamboo
    cp ${origdir}/bamboo ${name}/${installdir}/bamboo/bamboo
    chmod 755 ${name}/${installdir}/bamboo/bamboo

    # Link default confiugration
    mkdir -p ${name}/etc/bamboo
    cp -rp ${origdir}/config/* ${name}/etc/bamboo/

    # Distribute UI webapp
    mkdir -p ${name}/${installdir}/bamboo/webapp
    cp -rp ${origdir}/webapp/dist ${name}/${installdir}/bamboo/webapp/dist
    cp -rp ${origdir}/webapp/fonts ${name}/${installdir}/bamboo/webapp/fonts
    cp ${origdir}/webapp/index.html ${name}/${installdir}/bamboo/webapp/index.html

    # Versioning
    echo ${version} > ${name}/${installdir}/bamboo/VERSION
    pushd ${name}
}

function mkdeb() {
  # rubygem: fpm
  fpm -t ${pkgtype} \
    -n ${name} \
    -v ${version}${package_version} \
    --description "${description}" \
    --url="${url}" \
    -a ${arch} \
    --category ${section} \
    --vendor "Qubit" \
    --after-install ../../build.rpm.after-install \
    --after-remove  ../../build.rpm.after-remove \
    --before-remove ../../build.before-remove \
    -m "${USER}@${HOSTNAME}" \
    --license "${license}" \
    --prefix=/ \
    -s dir \
    -- \
    ../../init.d-bamboo-server=/etc/init.d/bamboo-server \
    ../../haproxy-restart-wrapper=/usr/local/bin/ \
    .

#    --deb-upstart ../../bamboo-server \

  mkdir -p ${origdir}/${outputdir}
  mv ${name}*.${pkgtype} ${origdir}/${outputdir}/
  popd
}

function main() {
    cleanup
    bootstrap
    build
    mkdeb
}

main
