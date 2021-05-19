/*
 * C2Xapplication.cc
 *
 *  Created on: May 6, 2019
 *      Author: pannu
 */

#include "C2XApplication.h"
#include "../message/C2XMessage_m.h"

#include "veins/modules/utility/Consts80211p.h"
#include "veins/base/utils/SimpleAddress.h"

Define_Module(C2XApplication);

C2XApplication::~C2XApplication() {
    // TODO Auto-generated destructor stub
}

void C2XApplication::initialize(int stage) {
    Veins::BaseApplLayer::initialize(stage);
    delayVOSignal = registerSignal("delayVO");
    delayVISignal = registerSignal("delayVI");
    delayBESignal = registerSignal("delayBE");
    delayBKSignal = registerSignal("delayBK");
    countVOSignal = registerSignal("countVO");
    countVISignal = registerSignal("countVI");
    countBESignal = registerSignal("countBE");
    countBKSignal = registerSignal("countBK");
    if (stage == 0) {
        std::cout << "application initialized" << std::endl;
        headerLength = par("headerLength");
        packetLength = par("packetLength");

        // TODO: schedule event for stat recording, e.g., goodput

        // TODO: read the parameter sendVia__ and accordingly schedule events
        sendViaVO = par("sendViaVO").boolValue();
        sendViaVI = par("sendViaVI").boolValue();
        sendViaBE = par("sendViaBE").boolValue();
        sendViaBK = par("sendViaBK").boolValue();

        if (sendViaVO) {
            cMessage *timerVO = new cMessage("timerVO", SEND_PKT_VO_EVT);
            scheduleAt(simTime() + par("arrival_vo").doubleValue(), timerVO);
        }
        if (sendViaVI) {
            cMessage *timerVI = new cMessage("timerVI", SEND_PKT_VI_EVT);
            scheduleAt(simTime() + par("arrival_vi").doubleValue(), timerVI);
        }
        if (sendViaBE) {
            cMessage *timerBE = new cMessage("timerBE", SEND_PKT_BE_EVT);
            scheduleAt(simTime() + par("arrival_be").doubleValue(), timerBE);
        }
        if (sendViaBK) {
            cMessage *timerBK = new cMessage("timerBK", SEND_PKT_BK_EVT);
            scheduleAt(simTime() + par("arrival_bk").doubleValue(), timerBK);
        }
        cMessage *stats = new cMessage("statsRecord", RECORD_STATS_EVT);
        scheduleAt(simTime() + delay, stats);
    }
}

void C2XApplication::handleSelfMsg(cMessage* msg) {
    switch (msg->getKind()) {
    case SEND_PKT_VO_EVT: {
        // TODO: create c2xmessage, and send via AC_VO
        C2XMessage *voMessage = new C2XMessage();
        populateAndSendPacket(voMessage, USER_PRIORITY_VO);
        scheduleAt(simTime() + par("arrival_vo"), msg);
        break;
    }
    case SEND_PKT_VI_EVT: {
        // TODO: create c2xmessage, and send via AC_VI
        C2XMessage *viMessage = new C2XMessage();
        populateAndSendPacket(viMessage, USER_PRIORITY_VI);
        scheduleAt(simTime() + par("arrival_vi"), msg);
        break;
    }
    case SEND_PKT_BE_EVT: {
        // TODO: create c2xmessage, and send via AC_BE
        C2XMessage *beMessage = new C2XMessage();
        populateAndSendPacket(beMessage, USER_PRIORITY_BE);
        scheduleAt(simTime() + par("arrival_be"), msg);
        break;
    }
    case SEND_PKT_BK_EVT: {
        // TODO: create c2xmessage, and send via AC_BK
        C2XMessage *bkMessage = new C2XMessage();
        populateAndSendPacket(bkMessage, USER_PRIORITY_BK);
        scheduleAt(simTime() + par("arrival_bk"), msg);
        break;
    }
    case RECORD_STATS_EVT: {
        // TODO: record statistics
        emit(countVOSignal, countVO);
        emit(countVISignal, countVI);
        emit(countBESignal, countBE);
        emit(countBKSignal, countBK);
        countVO = 0;
        countVI = 0;
        countBE = 0;
        countBK = 0;
        scheduleAt(simTime() + delay, msg);
        break;
    }
    default: {
        throw new cRuntimeError("unknown self message type");
        break;
    }
    }
}

void C2XApplication::finish() {
    // record scalars
    // cancel scheduled events, if any
}

void C2XApplication::handleLowerMsg(cMessage *msg) {
    // received a packet from MAC
    EV << "Received packet from MAC\n";

    C2XMessage* pkt = dynamic_cast<C2XMessage*>(msg);
    if (pkt) {
        switch (pkt->getUserPriority()) {
        case USER_PRIORITY_VO:
            d_VO = simTime() - pkt->getSendTime();
            EV << "Delay for VO " << d_VO <<"\n";
            emit(delayVOSignal, d_VO);
            countVO++;
            break;
        case USER_PRIORITY_VI:
            d_VI = simTime() - pkt->getSendTime();
            EV << "Delay for VI " << d_VI <<"\n";
            emit(delayVISignal, d_VI);
            countVI++;
            break;
        case USER_PRIORITY_BE:
            d_BE = simTime() - pkt->getSendTime();
            EV << "Delay for BE " << d_BE <<"\n";
            emit(delayBESignal, d_BE);
            countBE++;
            break;
        case USER_PRIORITY_BK:
            d_BK = simTime() - pkt->getSendTime();
            EV << "Delay for BK " << d_BK <<"\n";
            emit(delayBKSignal, d_BK);
            countBK++;
            break;
        default:
            throw new cRuntimeError("unknown user priority of received packet!");
            break;
        }
    }
    delete msg;
}

void C2XApplication::handleLowerControl(cMessage *msg) {
    EV << "Received packet from MAC\n";
    delete msg;
}

void C2XApplication::populateAndSendPacket(C2XMessage* pkt, int userPriority) {
    // populate the packet
    pkt->setRecipientAddress(Veins::LAddress::L2BROADCAST());
    pkt->setBitLength(headerLength);
    pkt->addBitLength(packetLength);

    pkt->setPsid(-1);
    pkt->setChannelNumber(static_cast<int>(Veins::Channel::cch));
    pkt->setUserPriority(userPriority);
    pkt->setId(getSimulation()->getUniqueNumber());
    pkt->setSendTime(simTime());

    EV << "Sending packet with priority *" << pkt->getUserPriority() << "*\n";

    // send the packet to mac
    sendDown(pkt);
}

void C2XApplication::sendDown(cMessage* msg) {
    //checkAndTrackPacket(msg);
    Veins::BaseApplLayer::sendDown(msg);
}

void C2XApplication::checkAndTrackPacket(cMessage* msg) {
    // can count and keep track of sent messages here...
    switch (dynamic_cast<C2XMessage*>(msg)->getUserPriority()) {
    case USER_PRIORITY_VO:
        countVO++;
        EV <<"Sent VO Packets "<< countVO <<"\n";
        break;
    case USER_PRIORITY_VI:
        countVI++;
        EV <<"Sent VI Packets "<< countVI <<"\n";
        break;
    case USER_PRIORITY_BE:
        countBE++;
        EV <<"Sent BE Packets "<< countBE <<"\n";
        break;
    case USER_PRIORITY_BK:
        countBK++;
        EV <<"Sent BK Packets "<< countBK <<"\n";
        break;
    default:
        throw new cRuntimeError("unknown user priority !");
        break;
    }
}

