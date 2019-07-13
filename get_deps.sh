#!/usr/bin/env bash

# set -x
set -e

if [[ "$1" == "cpu" ]]; then
	GPU=no
elif [[ "$1" == "gpu" ]]; then
	GPU=yes
else
	GPU=${GPU:-no}
fi

OS=$(python3 deps/readies/bin/platform --os)
ARCH=$(python3 deps/readies/bin/platform --arch)

cd deps

### DLPACK

if [[ ! -d dlpack ]]; then
    echo "Cloning dlpack..."
    git clone --depth 1 https://github.com/dmlc/dlpack.git
	echo "Done."
else
	echo "dlpack is in place."
fi

### TENSORFLOW

# TF_VERSION=1.12.0

if [[ ! -d tensorflow ]]; then
	echo "Installing TensorFlow..."
	
	if [[ $OS == linux ]]; then
		TF_OS="linux"
		if [[ $GPU == no ]]; then
			TF_BUILD="cpu"
		else
			TF_BUILD="gpu"
		fi
		if [[ $ARCH == x64 ]]; then
			TF_VERSION=1.12.0
			TF_ARCH=x86_64
			LIBTF_URL_BASE=https://storage.googleapis.com/tensorflow/libtensorflow
		elif [[ $ARCH == arm64v8 ]]; then
			TF_VERSION=1.13.1
			TF_ARCH=arm64
			LIBTF_URL_BASE=https://s3.amazonaws.com/redismodules/tensorflow
		fi
	elif [[ $OS == macosx ]]; then
		TF_VERSION=1.12.0
		TF_OS=darwin
		TF_BUILD=cpu
		TF_ARCH=x86_64
		LIBTF_URL_BASE=https://storage.googleapis.com/tensorflow/libtensorflow
	fi

	LIBTF_ARCHIVE=libtensorflow-${TF_BUILD}-${TF_OS}-${TF_ARCH}-${TF_VERSION}.tar.gz

	[[ ! -f $LIBTF_ARCHIVE ]] && wget --quiet $LIBTF_URL_BASE/$LIBTF_ARCHIVE

	rm -rf tensorflow.x
	mkdir tensorflow.x
	tar xf $LIBTF_ARCHIVE --no-same-owner --strip-components=1 -C tensorflow.x
	mv tensorflow.x tensorflow
	
	echo "Done."
else
	echo "TensorFlow is in place."
fi

### PYTORCH

PT_VERSION=1.1.0
#PT_VERSION="latest"

if [[ ! -d libtorch ]]; then
	echo "Installing libtorch..."

	if [[ $OS == linux ]]; then
		PT_OS=linux
		if [[ $GPU == no ]]; then
			PT_BUILD=cpu
		else
			PT_BUILD=cu90
		fi
		if [[ $ARCH == x64 ]]; then
			PT_ARCH=x86_64
		elif [[ $ARCH == arm64v8 ]]; then
			PT_ARCH=arm64
		fi
	elif [[ $OS == macosx ]]; then
		PT_OS=macos
		PT_BUILD=cpu
	fi

	[[ "$PT_VERSION" == "latest" ]] && PT_BUILD=nightly/${PT_BUILD}

	LIBTORCH_ARCHIVE=libtorch-${PT_BUILD}-${PT_OS}-${PT_ARCH}-${PT_VERSION}.tar.gz
	[[ -z $LIBTORCH_URL ]] && LIBTORCH_URL=https://s3.amazonaws.com/redismodules/pytorch/$LIBTORCH_ARCHIVE

	[[ ! -f $LIBTORCH_ARCHIVE ]] && wget -q $LIBTORCH_URL

	rm -rf libtorch.x
	mkdir libtorch.x

	tar xf $LIBTORCH_ARCHIVE --no-same-owner -C libtorch.x
	mv libtorch.x/libtorch libtorch
	rmdir libtorch.x
	
	echo "Done."
else
	echo "librotch is in place."
fi

### MKL

if [[ ! -d mkl ]]; then
	MKL_VERSION=0.17.1
	MKL_BUNDLE_VER=2019.0.1.20180928
	if [[ $OS == macosx ]]; then
		echo "Installing MKL..."

		MKL_OS=mac
		MKL_ARCHIVE=mklml_${MKL_OS}_${MKL_BUNDLE_VER}.tgz
		[[ ! -e ${MKL_ARCHIVE} ]] && wget -q https://github.com/intel/mkl-dnn/releases/download/v${MKL_VERSION}/${MKL_ARCHIVE}
		
		rm -rf mkl.x
		mkdir mkl.x
		tar xzf ${MKL_ARCHIVE} --no-same-owner --strip-components=1 -C mkl.x
		mv mkl.x mkl
		
		
		echo "Done."
	fi
else
	echo "mkl is in place."
fi

###  ONNXRUNTIME

ORT_VERSION="0.4.0"

if [[ $OS == linux ]]; then
	if [[ $GPU == no ]]; then
		ORT_OS="linux-x64"
		ORT_BUILD="cpu"
	else
		ORT_OS="linux-x64-gpu"
		ORT_BUILD="gpu"
	fi
elif [[ $OS == macosx ]]; then
	ORT_OS="osx-x64"
	ORT_BUILD=""
fi

ORT_ARCHIVE=onnxruntime-${ORT_OS}-${ORT_VERSION}.tgz

if [[ ! -d onnx ]]; then
	echo "Installing onnx..."

	if [[ ! -e ${ORT_ARCHIVE} ]]; then
		echo "Downloading ONNXRuntime ${ORT_VERSION} ${ORT_BUILD} ..."
		wget -q https://github.com/Microsoft/onnxruntime/releases/download/v${ORT_VERSION}/${ORT_ARCHIVE}
		echo "Done."
	fi

	rm -rf onnx.x
	mkdir onnx.x
	tar xzf ${ORT_ARCHIVE} --no-same-owner --strip-components=1 -C onnx.x
	mv onnx.x onnx
	
	echo "Done."
else
	echo "onnx is in place."
fi

### Collect libraries

if [[ ! -d install ]]; then
	echo "Collecting binaries..."

	rm -rf install.x
	mkdir install.x
	python3 collect-bin.py --into install.x
	mv install.x install
	
	echo "Done."
fi

# echo "Done"
