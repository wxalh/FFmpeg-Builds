#!/bin/bash

RKMPP_LEGACY=1

ffbuild_dockeraddin() {
    to_df 'ENV RKMPP_LEGACY=1'
}
