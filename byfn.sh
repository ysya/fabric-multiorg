#!/bin/bash

# five machines
# 192.168.64.136 peer0.org1.example.com 51100
# 192.168.64.225 peer1.org1.example.com 51110
# 192.168.64.243 peer0.org2.example.com 51200
# 192.168.64.249 peer1.org2.example.com 51210
# 192.168.64.69    orderer0.example.com 51000
# 192.168.64.69    orderer1.example.com 51001
# 192.168.64.69    orderer2.example.com 51002


MODE=$1
CHANNEL1_NAME="all"
CHANNEL2_NAME="scmh"
CHANNEL3_NAME="cbsc"
CHANNEL4_NAME="tmh"
CHANNEL1_PROFILE="OmniHealthChannelALL"
CHANNEL2_PROFILE="OmniHealthChannelSCMH"
CHANNEL3_PROFILE="OmniHealthChannelCBSC"
CHANNEL4_PROFILE="OmniHealthChannelTMH"
ORDERER_NAME="OmniHealth"
ORG1="Insurance0001"
ORG2="Hospital0001"
ORG3="Hospital0002"
ORG4="Hospital0003"

CHAINCODENAME="chaincodeName"
CHAINCODEVERSION="3.1"
CURRENTDIR=`pwd`
echo "CURRENTDIR = $CURRENTDIR"

ORDERER_CA=$CURRENTDIR/crypto-config/ordererOrganizations/example.com/orderers/${ORDERER_NAME,,}0.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
PEER0_ORG1_CA=$CURRENTDIR/crypto-config/peerOrganizations/${ORG1,,}.example.com/peers/peer0.${ORG1,,}.example.com/tls/ca.crt
PEER0_ORG2_CA=$CURRENTDIR/crypto-config/peerOrganizations/${ORG2,,}.example.com/peers/peer0.${ORG2,,}.example.com/tls/ca.crt
PEER0_ORG3_CA=$CURRENTDIR/crypto-config/peerOrganizations/${ORG3,,}.example.com/peers/peer0.${ORG3,,}.example.com/tls/ca.crt
PEER0_ORG4_CA=$CURRENTDIR/crypto-config/peerOrganizations/${ORG4,,}.example.com/peers/peer0.${ORG4,,}.example.com/tls/ca.crt

# Print the usage message
function printHelp() {
    echo "Usage: "
    echo "  byfn.sh <mode>"
    echo "    - 'generateCert' - generate required certificates "
    echo "    - 'generateChannel' - generate required genesis block "
    echo "    - 'cleanup' - "
    echo "    - 'dispatch' - "
    echo "    - 'runOrderer' - "
    echo "    - 'createChannel' - "
    echo "    - 'installChaincode' - "
    echo "    - 'instantiateChaincode' - "
    echo "    - 'invokeChaincode' - "
    echo "    - 'updateAnchor' - "
    echo "    - 'queryChaincode' - "  
    echo "    - 'joinChannel' - "
}

# Generates Org certs using cryptogen tool
function generateCerts() {
    echo
    echo "##########################################################"
    echo "##### Generate certificates using cryptogen tool #########"
    echo "##########################################################"

    if [ -d "crypto-config" ]; then
      rm -Rf crypto-config
    fi
    set -x
    ./cryptogen generate --config=./crypto-config.yaml
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate certificates..."
      exit 1
    fi
    echo
}


function generateChannelArtifacts() {
  
# Generate Orderer Genesis block

    if [ -d "channel-artifacts" ]; then
      rm -rf channel-artifacts/*
    fi
    mkdir channel-artifacts
    echo "##########################################################"
    echo "#########  Generating Orderer Genesis block ##############"
    echo "##########################################################"
    # Note: For some unknown reason (at least for now) the block file can't be
    # named orderer.genesis.block or the orderer will fail to launch!
    set -x
    ./configtxgen -profile OmniHealthGenesis -outputBlock ./channel-artifacts/${ORDERER_NAME,,}.block
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate orderer genesis block..."
      exit 1
    fi

# Generate Channel Block

    echo
    echo "###################################################################################"
    echo "### Generating ${CHANNEL1_PROFILE} configuration transaction '${CHANNEL1_NAME}' ###"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL1_PROFILE} -outputCreateChannelTx ./channel-artifacts/${CHANNEL1_NAME}.tx -channelID $CHANNEL1_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate channel configuration transaction..."
      exit 1
    fi

    echo
    echo "###################################################################################"
    echo "### Generating ${CHANNEL2_PROFILE} configuration transaction '${CHANNEL2_NAME}' ###"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL2_PROFILE} -outputCreateChannelTx ./channel-artifacts/${CHANNEL2_NAME}.tx -channelID $CHANNEL2_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate channel configuration transaction..."
      exit 1
    fi

    echo
    echo "###################################################################################"
    echo "### Generating ${CHANNEL3_PROFILE} configuration transaction '${CHANNEL3_NAME}' ###"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL3_PROFILE} -outputCreateChannelTx ./channel-artifacts/${CHANNEL3_NAME}.tx -channelID $CHANNEL3_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate channel configuration transaction..."
      exit 1
    fi

    echo
    echo "###################################################################################"
    echo "### Generating ${CHANNEL4_PROFILE} configuration transaction '${CHANNEL4_NAME}' ###"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL4_PROFILE} -outputCreateChannelTx ./channel-artifacts/${CHANNEL4_NAME}.tx -channelID $CHANNEL4_NAME
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate channel configuration transaction..."
      exit 1
    fi

# ========== Channel1 anchor peer update Start ==========

    echo
    echo "###################################################################################"
    echo "#######    Generating anchor peer update for ${ORG1,,} in ${CHANNEL1_NAME}    #######"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL1_PROFILE} -outputAnchorPeersUpdate \
    ./channel-artifacts/${ORG1}MSPanchors-${CHANNEL1_NAME}.tx -channelID ${CHANNEL1_NAME} -asOrg ${ORG1,,}
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for ${ORG1,,} in ${CHANNEL1_NAME}..."
      exit 1
    fi

    echo
    echo "###################################################################################"
    echo "#######    Generating anchor peer update for ${ORG2,,} in ${CHANNEL1_NAME}    #######"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL1_PROFILE} -outputAnchorPeersUpdate \
    ./channel-artifacts/${ORG2}MSPanchors-${CHANNEL1_NAME}.tx -channelID ${CHANNEL1_NAME} -asOrg ${ORG2,,}
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for ${ORG2,,} in ${CHANNEL1_NAME}..."
      exit 1
    fi
    echo

    echo
    echo "####################################################################################"
    echo "#######    Generating anchor peer update for ${ORG3,,} in ${CHANNEL1_NAME}    ########"
    echo "####################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL1_PROFILE} -outputAnchorPeersUpdate \
    ./channel-artifacts/${ORG3}MSPanchors-${CHANNEL1_NAME}.tx -channelID ${CHANNEL1_NAME} -asOrg ${ORG3,,}
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for ${ORG3,,} in ${CHANNEL1_NAME}..."
      exit 1
    fi
    echo

    echo
    echo "###################################################################################"
    echo "#######    Generating anchor peer update for ${ORG4,,} in ${CHANNEL1_NAME}    #######"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL1_PROFILE} -outputAnchorPeersUpdate \
    ./channel-artifacts/${ORG4}MSPanchors-${CHANNEL1_NAME}.tx -channelID ${CHANNEL1_NAME} -asOrg ${ORG4,,}
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for ${ORG4,,} in ${CHANNEL1_NAME}..."
      exit 1
    fi
    echo
# ========== Channel1 anchor peer update End ==========

# ========== Channel2 anchor peer update Start ==========

    echo
    echo "###################################################################################"
    echo "#######    Generating anchor peer update for ${ORG1,,} in ${CHANNEL2_NAME}    #######"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL2_PROFILE} -outputAnchorPeersUpdate \
    ./channel-artifacts/${ORG1}MSPanchors-${CHANNEL2_NAME}.tx -channelID ${CHANNEL2_NAME} -asOrg ${ORG1,,}
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for ${ORG1,,} in ${CHANNEL2_NAME}..."
      exit 1
    fi

    echo
    echo "###################################################################################"
    echo "#######    Generating anchor peer update for ${ORG2,,} in ${CHANNEL2_NAME}    #######"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL2_PROFILE} -outputAnchorPeersUpdate \
    ./channel-artifacts/${ORG2}MSPanchors-${CHANNEL2_NAME}.tx -channelID ${CHANNEL2_NAME} -asOrg ${ORG2,,}
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for ${ORG2,,} in ${CHANNEL2_NAME}..."
      exit 1
    fi
    echo

    # ========== Channel2 anchor peer update End ==========

    # ========== Channel3 anchor peer update Start ==========

    echo
    echo "###################################################################################"
    echo "#######    Generating anchor peer update for ${ORG1,,} in ${CHANNEL3_NAME}    #######"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL3_PROFILE} -outputAnchorPeersUpdate \
    ./channel-artifacts/${ORG1}MSPanchors-${CHANNEL3_NAME}.tx -channelID ${CHANNEL3_NAME} -asOrg ${ORG1,,}
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for ${ORG1,,} in ${CHANNEL3_NAME}..."
      exit 1
    fi

    echo
    echo "###################################################################################"
    echo "#######    Generating anchor peer update for ${ORG3,,} in ${CHANNEL3_NAME}    #######"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL3_PROFILE} -outputAnchorPeersUpdate \
    ./channel-artifacts/${ORG3}MSPanchors-${CHANNEL3_NAME}.tx -channelID ${CHANNEL3_NAME} -asOrg ${ORG3,,}
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for ${ORG3,,} in ${CHANNEL3_NAME}..."
      exit 1
    fi
    echo

    # ========== Channel3 anchor peer update End ==========

    # ========== Channel4 anchor peer update Start ==========

    echo
    echo "###################################################################################"
    echo "#######    Generating anchor peer update for ${ORG1,,} in ${CHANNEL4_NAME}    #######"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL4_PROFILE} -outputAnchorPeersUpdate \
    ./channel-artifacts/${ORG1}MSPanchors-${CHANNEL4_NAME}.tx -channelID ${CHANNEL4_NAME} -asOrg ${ORG1,,}
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for ${ORG1,,} in ${CHANNEL4_NAME}..."
      exit 1
    fi

    echo
    echo "###################################################################################"
    echo "#######    Generating anchor peer update for ${ORG4,,} in ${CHANNEL4_NAME}    #######"
    echo "###################################################################################"
    set -x
    ./configtxgen -profile ${CHANNEL4_PROFILE} -outputAnchorPeersUpdate \
    ./channel-artifacts/${ORG4}MSPanchors-${CHANNEL4_NAME}.tx -channelID ${CHANNEL4_NAME} -asOrg ${ORG4,,}
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate anchor peer update for ${ORG4,,} in ${CHANNEL4_NAME}..."
      exit 1
    fi
    echo
    # ========== Channel4 anchor peer update End ==========
}


function disptchFiles() {
    echo
    echo "######################"
    echo "##### copy files #####"
    echo "######################"

    cd $CURRENTDIR
    mkdir multimachine  
    
    disptchFile4Orderer 0
    disptchFile4Orderer 1
    disptchFile4Orderer 2
    disptchFile4Orderer 3
    
    disptchFile4Peer 0 $ORG1
    # disptchFile4Peer 1 $ORG1
    disptchFile4Peer 0 $ORG2
    # disptchFile4Peer 1 $ORG2
    disptchFile4Peer 0 $ORG3
    # disptchFile4Peer 1 $ORG3
    disptchFile4Peer 0 $ORG4
    # disptchFile4Peer 1 $ORG4
}


function disptchFile4Orderer() {
    NUM=$1
    
    rm -rf run-orderer${NUM}
    mkdir run-orderer${NUM}
    cp orderer run-orderer${NUM}/
    cp channel-artifacts/${ORDERER_NAME,,}.block run-orderer${NUM}/
    cp -r crypto-config/ordererOrganizations/example.com/orderers/${ORDERER_NAME,,}${NUM}.example.com/msp/ run-orderer${NUM}/
    cp -r crypto-config/ordererOrganizations/example.com/orderers/${ORDERER_NAME,,}${NUM}.example.com/tls/ run-orderer${NUM}/
    cp orderer${NUM}.yaml run-orderer${NUM}/orderer.yaml
    
    tar -czvf multimachine/run-orderer${NUM}.tar.gz  run-orderer${NUM}/
}


function disptchFile4Peer() {
    PEER=$1
    ORG=$2
 
    cd $CURRENTDIR
    mydir=run-peer$PEER-org$ORG
    rm -rf $mydir
    mkdir $mydir
    cp peer $mydir/
    cp peer$PEER-${ORG}.core.yaml $mydir/core.yaml
    cp -r crypto-config/peerOrganizations/${ORG,,}.example.com/peers/peer$PEER.${ORG,,}.example.com/msp/ $mydir/
    cp -r crypto-config/peerOrganizations/${ORG,,}.example.com/peers/peer$PEER.${ORG,,}.example.com/tls/ $mydir/
    
    tar -czvf multimachine/$mydir.tar.gz  $mydir/
}

function runOrderer() {
    echo
    echo "################################################################"
    echo "##### move to "run-orderer" folder and run ./orderer start #####"
    echo "################################################################"
    
}

function runPeer() {
    echo
    echo "#############################################################"
    echo "##### move to run-peer?-org? and run ./peer node start  #####"
    echo "#############################################################"
}

function cleanup() {
    echo
    echo "##########################################################"
    echo "##### cleanup #####"
    echo "##########################################################"

    rm -rf crypto-config/
    rm -rf channel-artifacts/
    rm -rf run-orderer0/  
    rm -rf run-orderer1/  
    rm -rf run-orderer2/
      
    rm -rf run-peer0-org1/
    rm -rf run-peer1-org1/
    rm -rf run-peer0-org2/
    rm -rf run-peer1-org2/
    rm -rf multimachine/
    rm -rf log.txt/
    if [ -f "${CHANNEL_NAME}.block" ]; then
      rm -rf ${CHANNEL_NAME}.block
    fi
        
}

function createChannel() {
	cd $CURRENTDIR/
    # PEER=$1
    # ORG=$2
    # setGlobals $PEER $ORG

    # CORE_PEER_LOCALMSPID="${ORG1}MSP"
    # CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    # CORE_PEER_MSPCONFIGPATH=$CURRENTDIR/crypto-config/peerOrganizations/${ORG1,,}.example.com/users/Admin@${ORG1,,}.example.com/msp
    # CORE_PEER_ADDRESS=peer0.${ORG1,,}.example.com:51100

	set -x
	CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA \
	CORE_PEER_LOCALMSPID=${ORG1}MSP \
    CORE_PEER_MSPCONFIGPATH=$CURRENTDIR/crypto-config/peerOrganizations/${ORG1,,}.example.com/users/Admin@${ORG1,,}.example.com/msp \
    CORE_PEER_ADDRESS=peer0.${ORG1,,}.example.com:51100 \
	./peer channel create -o ${ORDERER_NAME,,}0.example.com:51000 -c ${CHANNEL1_NAME,,} -f ./channel-artifacts/${CHANNEL1_NAME}.tx --tls true --cafile $ORDERER_CA --logging-level=debug 2>log.txt
	res=$?
    set +x
	
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '${CHANNEL1_NAME,,}' created ===================== "
	echo
}

function joinChannel() {
	cd $CURRENTDIR/
	PEER=$1
    ORG=$2 
	setGlobals $PEER $ORG
	
	set -x
	CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
	CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
	./peer channel join -b ${ORDERER_NAME}.block --logging-level=debug 2>log.txt
	res=$?
    set +x
	
	cat log.txt
	verifyResult $res "joinChannel peer$1-org$2 failed"
	echo "===================== peer$1-org$2.example.com success to join channel ===================== "
	echo
}

function installChaincode() {
	cd $CURRENTDIR/
	PEER=$1
    ORG=$2 
	setGlobals $PEER $ORG
	
	set -x
	CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
	GOPATH=$CURRENTDIR \
	CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
	./peer chaincode install -n $CHAINCODENAME -v $CHAINCODEVERSION -p chaincode/ --logging-level=debug 2>log.txt

	res=$?
    set +x
	
	cat log.txt
	verifyResult $res "installChaincode peer$1-org$2 failed"
	echo "===================== peer$1-org$2.example.com success to installChaincode ===================== "
	echo
}

function instantiateChaincode() {
	cd $CURRENTDIR/
	PEER=$1
    ORG=$2 
	setGlobals $PEER $ORG
	
	set -x
	CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
	CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
	./peer chaincode instantiate -o orderer0.example.com:51000 -C $CHANNEL_NAME  -n $CHAINCODENAME -v $CHAINCODEVERSION \
	--tls \
	--cafile $ORDERER_CA \
	-c '{"Args":["init","a","100","b","200"]}'  -P "OR ('Org1MSP.member', 'Org2MSP.member')" --logging-level=debug 2>log.txt
	res=$?
    set +x
	
	cat log.txt
	verifyResult $res "instantiateChaincode peer$1-org$2 failed"
	echo "===================== peer$1-org$2.example.com success to instantiateChaincode ===================== "
	echo
}

function invokeChaincode() {
    cd $CURRENTDIR/
    PEER=$1
    ORG=$2 
    setGlobals $PEER $ORG
	
    set -x
    CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
    CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
    ./peer chaincode invoke -o orderer0.example.com:51000 -C $CHANNEL_NAME \
    --tls \
	--cafile $ORDERER_CA \
	-n $CHAINCODENAME  -c '{"Args":["invoke","a","b","10"]}'  >&log.txt
    res=$?
    set +x
    cat log.txt
    verifyResult $res "Invoke execution on peer$1-org$2 failed "
    echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
    echo
}

function queryChaincode() {
    cd $CURRENTDIR/
    PEER=$1
    ORG=$2 
    setGlobals $PEER $ORG
    set -x
    CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
    CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
    ./peer chaincode query -C $CHANNEL_NAME -n $CHAINCODENAME -c '{"Args":["query","a"]}' >&log.txt
    res=$?
    set +x
    echo
    cat log.txt
    
    verifyResult $res "queryChaincode  on peer$1-org$2 failed "
    echo "========= Query successful on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' ===================== "
}

function updateAnchor() {
	cd $CURRENTDIR/
	PEER=$1
    ORG=$2 
	setGlobals $PEER $ORG
	
	set -x
	CORE_PEER_TLS_ROOTCERT_FILE=$CORE_PEER_TLS_ROOTCERT_FILE \
	CORE_PEER_LOCALMSPID=$CORE_PEER_LOCALMSPID CORE_PEER_MSPCONFIGPATH=$CORE_PEER_MSPCONFIGPATH CORE_PEER_ADDRESS=$CORE_PEER_ADDRESS \
	./peer channel update -o orderer0.example.com:51000 -c $CHANNEL_NAME -f channel-artifacts/Org${ORG}MSPanchors.tx --tls true --cafile $ORDERER_CA --logging-level=debug 2>log.txt
	res=$?
    set +x
	
	cat log.txt
	verifyResult $res "updateAnchor peer$1-org$2 failed"
	echo "===================== peer$1-org$2.example.com success to updateAnchor ===================== "
	echo
}

function verifyResult() {
    if [ $1 -ne 0 ]; then
      echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
      echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
      echo
      exit 1
    fi
}

function setGlobals() {
  
    PEER=$1
    ORG=$2
  
    echo "00 setGlobals $PEER, $ORG"
    if [ $ORG -eq 1 ]; then
      echo "02 setGlobals $PEER, $ORG"
      CORE_PEER_LOCALMSPID="${ORG1}MSP"
      CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
      CORE_PEER_MSPCONFIGPATH=$CURRENTDIR/crypto-config/peerOrganizations/${ORG1,,}.example.com/users/Admin@${ORG1,,}.example.com/msp
      if [ $PEER -eq 0 ]; then
        CORE_PEER_ADDRESS=peer0.${ORG1,,}.example.com:51100
      else
        CORE_PEER_ADDRESS=peer1.${ORG1,,}.example.com:51110
      fi
    elif [ $ORG -eq 2 ]; then
      CORE_PEER_LOCALMSPID="${ORG2}MSP"
      CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
      CORE_PEER_MSPCONFIGPATH=$CURRENTDIR/crypto-config/peerOrganizations/${ORG2,,}.example.com/users/Admin@${ORG2,,}.example.com/msp
      if [ $PEER -eq 0 ]; then
        CORE_PEER_ADDRESS=peer0.${ORG2,,}.example.com:51200
      else
        CORE_PEER_ADDRESS=peer1.${ORG2,,}.example.com:51210
      fi
    elif [ $ORG -eq 2 ]; then
      CORE_PEER_LOCALMSPID="${ORG3}MSP"
      CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
      CORE_PEER_MSPCONFIGPATH=$CURRENTDIR/crypto-config/peerOrganizations/${ORG3,,}.example.com/users/Admin@${ORG3,,}.example.com/msp
      if [ $PEER -eq 0 ]; then
        CORE_PEER_ADDRESS=peer0.${ORG3,,}.example.com:51200
      else
        CORE_PEER_ADDRESS=peer1.${ORG3,,}.example.com:51210
      fi
    elif [ $ORG -eq 2 ]; then
      CORE_PEER_LOCALMSPID="${ORG4}MSP"
      CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG4_CA
      CORE_PEER_MSPCONFIGPATH=$CURRENTDIR/crypto-config/peerOrganizations/${ORG4,,}.example.com/users/Admin@${ORG4,,}.example.com/msp
      if [ $PEER -eq 0 ]; then
        CORE_PEER_ADDRESS=peer0.${ORG4,,}.example.com:51200
      else
        CORE_PEER_ADDRESS=peer1.${ORG4,,}.example.com:51210
      fi
    fi
  
    echo "CORE_PEER_ADDRESS: $CORE_PEER_ADDRESS "
    echo "CORE_PEER_LOCALMSPID: $CORE_PEER_LOCALMSPID"
    echo "CORE_PEER_MSPCONFIGPATH: $CORE_PEER_MSPCONFIGPATH"
    echo "environment variables: begin"
    env | grep CORE
    echo "environment variables: end"
  
 }

if [ "${MODE}" == "cleanup" ]; then
    cleanup
elif [ "${MODE}" == "dispatch" ]; then
    disptchFiles
elif [ "${MODE}" == "runOrderer" ]; then 
    runOrderer
elif [ "${MODE}" == "createChannel" ]; then
    createChannel 0 1
elif [ "${MODE}" == "installChaincode" ]; then
    installChaincode 0 1
    installChaincode 0 2
elif [ "${MODE}" == "instantiateChaincode" ]; then
    instantiateChaincode 0 2
elif [ "${MODE}" == "invokeChaincode" ]; then
    invokeChaincode 0 1
    invokeChaincode 0 2
    echo "run two transaction in a time, one of them will be fail"
elif [ "${MODE}" == "updateAnchor" ]; then
    updateAnchor 0 1
    updateAnchor 0 2
elif [ "${MODE}" == "queryChaincode" ]; then
    queryChaincode 0 1
    queryChaincode 0 2
elif [ "${MODE}" == "invokeChaincode" ]; then
    invokeChaincode 0 1
    invokeChaincode 0 2
elif [ "${MODE}" == "joinChannel" ]; then
    joinChannel 0 1
    joinChannel 1 1
    joinChannel 0 2
    joinChannel 1 2
elif [ "${MODE}" == "generateCert" ]; then
    generateCerts
elif [ "${MODE}" == "generateChannel" ]; then
    generateChannelArtifacts
else
    printHelp
    echo "wrong commander: '${MODE}'"
fi