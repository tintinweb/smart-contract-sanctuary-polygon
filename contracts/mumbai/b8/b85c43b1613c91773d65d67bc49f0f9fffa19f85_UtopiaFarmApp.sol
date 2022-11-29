// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ModuleBase.sol";
import "./Lockable.sol";
import "./AppWallet.sol";
import "./PairPrice.sol";
import "./ECDSA.sol";
import "./UtopiaFarmAppData.sol";

contract UtopiaFarmApp is ModuleBase, Lockable, SafeMath, ECDSA {

    address internal signer;

    event seedSowed(uint256 sowId, uint32 roundIndex);
    event seedClaimed(uint256 amount);
    
    constructor(address _auth, address _moduleMgr) ModuleBase(_auth, _moduleMgr) {

    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function getSigner() external view returns (address res) {
        res = signer;
    }

    function sowSeed(uint256 amount, uint256 usdtIn, uint32 sowId, uint256 profitPercent, uint256 claimCycle, bytes memory signature) external lock {
        _sowSeed(msg.sender, amount, usdtIn, sowId, profitPercent, claimCycle, signature);
    }

    function _sowSeed(address account, uint256 amount, uint256 usdtIn, uint32 sowId, uint256 profitPercent, uint256 claimCycle, bytes memory signature) internal {

        string memory message = string(abi.encodePacked(Strings.addressToString(account), 
                                                        Strings.uint256ToString(amount), 
                                                        Strings.uint256ToString(usdtIn), 
                                                        Strings.uint256ToString(sowId),
                                                        Strings.uint256ToString(profitPercent), 
                                                        Strings.uint256ToString(claimCycle)
                                                    ));
        require(_IsSignValid(message, signature), "invalid signature");

        require(!UtopiaFarmAppData(moduleMgr.getUtopiaFarmAppData()).isShowIdExists(sowId), "sowid used");

        require(ERC20(auth.getFarmToken()).balanceOf(account) >= amount, "insufficient UTO");
        require(ERC20(auth.getFarmToken()).allowance(account, address(this)) >= amount, "UTO not approved");

        uint256 usdtAmount = PairPrice(moduleMgr.getPairPrice()).cumulateUSDTAmountOut(amount);
        require(usdtAmount >= usdtIn - usdtIn * PairPrice(moduleMgr.getPairPrice()).getPriceTolerance() / 1000, "slippage error");

        UtopiaFarmAppData(moduleMgr.getUtopiaFarmAppData()).increaseRoundNumber(1);
        uint32 roundIndex = UtopiaFarmAppData(moduleMgr.getUtopiaFarmAppData()).getCurrentRoundNumber();
        
        UtopiaFarmAppData(moduleMgr.getUtopiaFarmAppData()).newSowData(
            roundIndex,
            sowId,
            account, 
            amount, 
            usdtAmount,
            profitPercent,
            claimCycle
        );

        require(ERC20(auth.getFarmToken()).transferFrom(account, moduleMgr.getAppWallet(), amount), "sowSeed error 1");

        emit seedSowed(sowId, roundIndex);
    }

    function _IsSignValid(string memory message, bytes memory signature) internal view returns(bool) {
        return signer == recover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(bytes(message).length),
                    message
                )
            ),
            signature
        );
    }

    function claimedSeed(uint32 sowId) external lock {
        require(msg.sender != address(0));
        (bool res, uint256 amount, uint256 beginCulTime) = UtopiaFarmAppData(moduleMgr.getUtopiaFarmAppData()).checkMatured(msg.sender, sowId);
        require(res, "have no sowed to claim");
        UtopiaFarmAppData(moduleMgr.getUtopiaFarmAppData()).updateLastClaimTime(sowId, beginCulTime);
        require(AppWallet(moduleMgr.getAppWallet()).transferToken(auth.getFarmToken(), msg.sender, amount), "claimedSeed error 1");
        emit seedClaimed(amount);
    }

    function withdrawMyToken(address token, uint256 amount, uint32 withdrawId, bytes memory signature)
    external lock {
        // require(auth.getEnable(), "stopped");
        string memory message = string(abi.encodePacked(Strings.addressToString(msg.sender), 
                                                        Strings.addressToString(token), 
                                                        Strings.uint256ToString(amount),
                                                        Strings.uint256ToString(withdrawId)
                                                    ));
        require(_IsSignValid(message, signature), "invalid signature");
        require(!UtopiaFarmAppData(moduleMgr.getUtopiaFarmAppData()).getWithdrawStatus(withdrawId), "withdrawed");
        UtopiaFarmAppData(moduleMgr.getUtopiaFarmAppData()).setWithdrawStatus(withdrawId, true);
        require(AppWallet(moduleMgr.getAppWallet()).transferToken(token, msg.sender, amount), "withdrawMyToken error 1");
    }
}