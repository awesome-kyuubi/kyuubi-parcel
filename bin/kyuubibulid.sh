#!/bin/bash
set -x
set -e
#cm_ext branch
CM_EXT_BRANCH=cm5-5.15.0
kyuubi_version=1.6.1
parcel_version=${kyuubi_version}-1
kyuubi_package_url=https://archive.apache.org/dist/incubator/kyuubi/kyuubi-${kyuubi_version}-incubating/apache-kyuubi-${kyuubi_version}-incubating-bin.tgz
kyuubi_package_name=kyuubi-${parcel_version}
kyuubi_parcel_name="$kyuubi_package_name-el7.parcel"
kyuubi_service_name="KYUUBI"
kyuubi_package="$( basename $kyuubi_package_url )"
kyuubi_csd_bulid_name="csd_out"
kyuubi_parcel_build_name="parcel_out"
CM_EXT=../cm_ext
#Checkout if dir does not exist
if [ ! -d ${CM_EXT} ]; then
  git clone https://github.com/cloudera/cm_ext.git
fi
if [ ! -f $CM_EXT/validator/target/validator.jar ]; then
  cd $CM_EXT
  git checkout "$CM_EXT_BRANCH"
  mvn package
  cd ../bin
fi

function get_kyuubi_package {
if [ ! -d "${kyuubi_package_name}" ];then
  if [ ! -f "$kyuubi_package" ]; then
    wget $kyuubi_package_url
    tar -xvf ${kyuubi_package}
    mv apache-kyuubi-${kyuubi_version}-incubating-bin  $kyuubi_package_name
  fi
fi
}

function build_kyuubi_parcel {
  pwd
  cp -a ../parcel/kyuubi-parcel-src/meta $kyuubi_package_name
  sed -i -e "s/%SERVICEVERSION%/$parcel_version/" $kyuubi_package_name/meta/parcel.json
  java -jar $CM_EXT/validator/target/validator.jar -d ./$kyuubi_package_name
  mkdir -p $kyuubi_parcel_build_name
  tar zcvhf $kyuubi_parcel_build_name/$kyuubi_parcel_name $kyuubi_package_name --owner=root --group=root
  java -jar $CM_EXT/validator/target/validator.jar -f ./$kyuubi_parcel_build_name/$kyuubi_parcel_name
  python $CM_EXT/make_manifest/make_manifest.py $kyuubi_parcel_build_name
  mv $kyuubi_parcel_build_name ../parcel
}


function build_kyuubi_csd {
  JARNAME=${kyuubi_service_name}-${kyuubi_version}.jar
  if [ -f "$kyuubi_csd_bulid_name/$JARNAME" ]; then
    return
  fi
  rm -rf $kyuubi_csd_bulid_name
  cp -a ../csd/kyuubi-csd-src $kyuubi_csd_bulid_name
  sed -i -e "s/%CSDVERSION%/$kyuubi_version/" ${kyuubi_csd_bulid_name}/descriptor/service.sdl
  java -jar ${CM_EXT}/validator/target/validator.jar -s ${kyuubi_csd_bulid_name}/descriptor/service.sdl
  jar -cvf $JARNAME -C ${kyuubi_csd_bulid_name} .
  mkdir ../csd/$kyuubi_csd_bulid_name
  mv $JARNAME ../csd/$kyuubi_csd_bulid_name
}

case $1 in
parcel)
  get_kyuubi_package
  build_kyuubi_parcel
  ;;
csd)
  build_kyuubi_csd
  ;;
whole)
  build_kyuubi_csd
  get_kyuubi_package
  build_kyuubi_parcel
  ;;
*)
  echo "Usage: $0 [parcel|csd|whole]"
  ;;
esac