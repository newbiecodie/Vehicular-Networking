/*
 * C2Xapplication.h
 *
 *  Created on: May 6, 2019
 *      Author: pannu
 */

#ifndef C2XAPPLICATION_H_
#define C2XAPPLICATION_H_

#include "veins/base/modules/BaseApplLayer.h"
#include "../message/C2XMessage_m.h"

class C2XApplication : public Veins::BaseApplLayer{
public:
    ~C2XApplication() override;
    void initialize(int stage) override;
    void finish() override;

    enum C2XappMessageKinds {
        SEND_PKT_VO_EVT = LAST_BASE_APPL_MESSAGE_KIND + 1, // Event to send AC_VO packet
        SEND_PKT_VI_EVT = LAST_BASE_APPL_MESSAGE_KIND + 2, // Event to send AC_VI packet
        SEND_PKT_BE_EVT = LAST_BASE_APPL_MESSAGE_KIND + 3, // Event to send AC_BE packet
        SEND_PKT_BK_EVT = LAST_BASE_APPL_MESSAGE_KIND + 4, // Event to send AC_BK packet
        RECORD_STATS_EVT = LAST_BASE_APPL_MESSAGE_KIND + 5 // Event to record stats like goodput
    };

    // Do not change the user priorities as they are mapped to access categories.
    enum PktPriorities {
        USER_PRIORITY_VO = 7,
        USER_PRIORITY_VI = 5,
        USER_PRIORITY_BE = 3,
        USER_PRIORITY_BK = 1
    };

protected:
    /** @brief handle messages from lower layer, i.e., MAC */
    void handleLowerMsg(cMessage* msg) override;

    /**
     * @brief Handle control messages from MAC
     **/
    void handleLowerControl(cMessage* msg) override;

    /** @brief handle self messages */
    void handleSelfMsg(cMessage* msg) override;

    /** @brief sets all the necessary fields in C2XMessage and send it to MAC */
    void populateAndSendPacket(C2XMessage* pkt, int userPriority);
    /**
     * @brief overloaded for error handling and stats recording purposes
     *
     * @param msg the message to be sent. Must be a BaseFrame1609_4
     */
    virtual void sendDown(cMessage* msg);

    /**
     * @brief helper function for error handling and stats recording purposes
     *
     * @param msg the message to be checked and tracked
     */
    virtual void checkAndTrackPacket(cMessage* msg);

protected:
    int packetLength;
    simtime_t delay = 1;
    bool sendViaVO;
    bool sendViaVI;
    bool sendViaBE;
    bool sendViaBK;
    int countVO = 0, countVI = 0, countBE = 0, countBK = 0;
    simsignal_t delayVOSignal;
    simsignal_t delayVISignal;
    simsignal_t delayBESignal;
    simsignal_t delayBKSignal;
    simtime_t d_BK, d_BE, d_VO, d_VI;
    simsignal_t countVOSignal;
    simsignal_t countVISignal;
    simsignal_t countBESignal;
    simsignal_t countBKSignal;
};

#endif /* C2XAPPLICATION_H_ */
