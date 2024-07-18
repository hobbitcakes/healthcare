#!/bin/bash

ADT="sample_data/synth_adt_a01.hl7"
ORU="sample_data/synth_oru.hl7"

if [ "$#" -eq "0" ]; then
  echo -e "No GCS path supplied. Supply a gcs path like gs://mybucket/path"
  exit 1
fi

GCS_PATH="$1"
BUCKET="$(echo $GCS_PATH | cut -d '/' -f 1-3)"
gcloud storage buckets describe $BUCKET 1>/dev/null
EXIT_CODE="$?"

if [ $EXIT_CODE -ne "0" ]; then
  echo -e "gcloud storage buckets describe ${BUCKET} failed."
  echo -e "Please check that the first and only parameter is the gcs bucket with path"
  exit 1
fi

upload_file () {  
  ADT_EPOCH="$(date +%s%N)"
  ORU_EPOCH="$(date +%s%N)"
  TEMP_ADT="$(mktemp adt-XXXXXXX.hl7)"
  TEMP_ORU="$(mktemp oru-XXXXXXX.hl7)"

  # Copy the template messages and replace the message control
  # id with linux epoch in nano seconds so each MSH header is 
  # unique
  cat $ADT | sed "s/MSHCONTROLID/${ADT_EPOCH}/g" > ${TEMP_ADT}
  cat $ORU | sed "s/MSHCONTROLID/${ORU_EPOCH}/g" > ${TEMP_ORU}

  gcloud storage cp ${TEMP_ADT} ${TEMP_ORU} $GCS_PATH/


  rm "${TEMP_ADT}"
  rm "${TEMP_ORU}"
}

upload_file
