//
//  SmartAdAward.swift
//  SmartAd
//
//  Created by shock on 2017. 10. 23..
//  Copyright © 2017년 shock. All rights reserved.
//

import Foundation
import GoogleMobileAds
import FBAudienceNetwork
import ShockExtension

protocol SmartAdAwardDelegate: NSObjectProtocol {
    func SmartAdAwardDone(_ isAward: Bool)
    func SmartAdAwardFail(_ error: Error?)
}

open class SmartAdAward: NSObject {
    var delegate    : SmartAdAwardDelegate?
    
    fileprivate var controller   : UIViewController?
    fileprivate var googleID     : String?
    fileprivate var facebookID   : String?
    fileprivate var isGoogleFirst: Bool = true
    fileprivate var loadingAlert : UIAlertController?
    fileprivate var isAward      : Bool = false
    
    fileprivate var fRewardedVideoAd: FBRewardedVideoAd?
    
    @objc
    public convenience init(_ controller: UIViewController, googleID: String?, facebookID: String?, isGoogleFirst: Bool = true) {
        self.init()
        
        self.controller    = controller
        self.googleID      = googleID
        self.facebookID    = facebookID
        self.isGoogleFirst = isGoogleFirst
        self.delegate      = controller as? SmartAdAwardDelegate
    }
    
    @objc
    public func showAd() {
        if SmartAd.IsShowAd(self) {
            loadingAlert = UIAlertController.loading(controller!, loadingStyle: .gray) { (loading) in
                if self.isGoogleFirst {
                    self.showGoogle()
                } else {
                    self.showFacebook()
                }
            }
        }
    }
}

// Google

extension SmartAdAward: GADRewardBasedVideoAdDelegate {
    func showGoogle() {
        if let id = googleID {
            GADRewardBasedVideoAd.sharedInstance().delegate = self
            GADRewardBasedVideoAd.sharedInstance().load(SmartAd.googleRequest, withAdUnitID: id)
        } else {
            loadingAlert?.dismiss(animated: true, completion: {
                self.delegate?.SmartAdAwardFail(nil)
            })
        }
    }
    
    // 광고 로딩 완료
    public func rewardBasedVideoAdDidReceive(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        loadingAlert?.dismiss(animated: true, completion: {
            GADRewardBasedVideoAd.sharedInstance().present(fromRootViewController: self.controller!) // 광고 오픈
        })
    }
    
    // 광고 로딩 싫패
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didFailToLoadWithError error: Error) {
        if !isGoogleFirst {
            loadingAlert?.dismiss(animated: true, completion: {
                self.delegate?.SmartAdAwardFail(error)
            })
        } else {
            showFacebook()
        }
    }
    
    // 광고를 끝까지 시청해서 보상 완료
    public func rewardBasedVideoAd(_ rewardBasedVideoAd: GADRewardBasedVideoAd, didRewardUserWith reward: GADAdReward) {
        isAward = true
    }
    
    // 광고가 닫혀야 완료 콜백이 가능하다.
    public func rewardBasedVideoAdDidClose(_ rewardBasedVideoAd: GADRewardBasedVideoAd) {
        delegate?.SmartAdAwardDone(isAward)
    }
}

// Facebook

extension SmartAdAward: FBRewardedVideoAdDelegate {
    func showFacebook() {
        if let id = facebookID {
            fRewardedVideoAd = FBRewardedVideoAd(placementID: id)
            fRewardedVideoAd?.delegate = self
            fRewardedVideoAd?.load()
        } else {
            loadingAlert?.dismiss(animated: true, completion: {
                self.delegate?.SmartAdAwardFail(nil)
            })
        }
    }
    
    // 광고 로딩 완료
    public func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        loadingAlert?.dismiss(animated: true, completion: {
            self.fRewardedVideoAd?.show(fromRootViewController: self.controller!) // 광고 오픈
        })
    }
    
    // 광고 로딩 싫패
    public func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
        if isGoogleFirst {
            loadingAlert?.dismiss(animated: true, completion: {
                self.delegate?.SmartAdAwardFail(error)
            })
        } else {
            showGoogle()
        }
    }
    
    // 광고를 끝까지 시청해서 보상 완료
    public func rewardedVideoAdComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        isAward = true
    }
    
    // 설치 버튼 클릭 시
    public func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        printLog("설치")
    }
    
    // 광고창을 닫을때 발생 (보상과 상관 없다)
    public func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        delegate?.SmartAdAwardDone(isAward)
    }
}






