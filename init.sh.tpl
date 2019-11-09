#!/usr/bin/env bash
gsutil cp gs://${bucket}/hashitools.rpm .
rpm -i hashitools.rpm