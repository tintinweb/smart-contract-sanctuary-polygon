/**
 *Submitted for verification at polygonscan.com on 2022-09-25
*/

// contracts/OPT_LOCK.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);
}

contract OPT_LOCK {
    uint128 THREE_HOURS = 10800;
    enum TRADE_STATE {
        PREMIUM_PENDING,
        OPEN,
        LOCKED,
        PRICE_CONFIRMING,
        DISPUTE,
        DELIVERED,
        EXPIRED,
        WITHDRAW
    }
    Trade[] trades;
    mapping(address => uint256[]) sellingTrades;
    mapping(address => uint256[]) buyingTrades;
    struct Trade {
        uint256 id;
        address seller;
        address buyer;
        address baseTokenAdd;
        address contraTokenAdd;
        uint256 notional;
        uint256 premium;
        uint256 strike;
        uint256 maturity;
        bool isCall;
        TRADE_STATE state;
        uint256 indexPrice;
        uint256 ts;
    }

    function sellTo(
        address buyer,
        address baseTokenAdd,
        address contraTokenAdd,
        uint256 notional,
        uint256 strike, //price*10000
        uint256 maturity,
        bool isCall
    ) public returns (uint256){
        if (isCall) {
            require(
                IERC20(baseTokenAdd).transferFrom(
                    msg.sender,
                    address(this),
                    notional
                ),
                "payment failed"
            );
        } else {
            require(
                IERC20(contraTokenAdd).transferFrom(
                    msg.sender,
                    address(this),
                    notional
                ),
                "payment failed"
            );
        }
        uint256 idx = trades.length;
        Trade memory trade = Trade(
            idx,
            payable(msg.sender),
            buyer,
            baseTokenAdd,
            contraTokenAdd,
            notional,
            0,
            strike, //strike price is in wei
            maturity,
            isCall,
            TRADE_STATE.PREMIUM_PENDING,
            0,
            block.timestamp
        );
        trades.push(trade);
        sellingTrades[msg.sender].push(idx);
        buyingTrades[buyer].push(idx);
        return idx;
    }

    function setPremium(uint256 tradeId, uint256 premium)public{
        Trade memory t = trades[tradeId];
        require(
            t.seller == msg.sender,
            "only seller is able to withdraw expired trades"
        );
        if (t.state == TRADE_STATE.PREMIUM_PENDING || t.state==TRADE_STATE.OPEN) {
            trades[tradeId].premium = premium;
            trades[tradeId].state = TRADE_STATE.OPEN;
        }
    }

    function withdraw(uint256 id) public {
        //validate msg.sender and trade seller
        Trade memory t = trades[id];
        require(
            t.seller == msg.sender,
            "only seller is able to withdraw expired trades"
        );
        if (t.state == TRADE_STATE.OPEN||t.state == TRADE_STATE.PREMIUM_PENDING) {
            trades[id].state = TRADE_STATE.WITHDRAW;
            require(
                IERC20(t.baseTokenAdd).transfer(t.seller, t.notional),
                "withdraw failed"
            );
        } else if (t.state == TRADE_STATE.PRICE_CONFIRMING) {
            trades[id].state = TRADE_STATE.EXPIRED;
            require(t.ts + THREE_HOURS < block.timestamp, "trade not expired");
            require(
                IERC20(t.baseTokenAdd).transfer(
                    t.seller,
                    t.notional + t.premium
                ),
                "withdraw expire trade failed"
            );
        } else {
            revert("unable to withdraw trade");
        }
    }

    function buy(uint256 id) public {
        require(
            trades[id].state == TRADE_STATE.OPEN,
            "trade not available to buy"
        );
        require(trades[id].buyer == msg.sender, "not allowed buyer");
        trades[id].state = TRADE_STATE.LOCKED;
        Trade memory t = trades[id];
        if (t.isCall) {
            require(
                IERC20(t.baseTokenAdd).transferFrom(
                    msg.sender,
                    address(this),
                    t.premium
                ),
                "failed to pay premium"
            );
        } else {
            require(
                IERC20(t.contraTokenAdd).transferFrom(
                    msg.sender,
                    address(this),
                    t.premium
                ),
                "failed to pay premium"
            );
        }
    }

    function setIndexPrice(uint256 id, uint256 indexPrice) public {
        Trade memory t = trades[id];
        require(block.timestamp > t.maturity, "trade not matured");
        require(
            t.seller == msg.sender,
            "only seller is able to update indexPrice"
        );
        if (t.state == TRADE_STATE.LOCKED) {
            trades[id].state = TRADE_STATE.PRICE_CONFIRMING;
        }
        trades[id].indexPrice = indexPrice;
        trades[id].ts = block.timestamp;
    }

    function disputeIndexPrice(uint256 id) public {
        require(
            trades[id].buyer == msg.sender,
            "only buyer is able to dispute indexPrice"
        );
        require(
            trades[id].state == TRADE_STATE.PRICE_CONFIRMING,
            "trade not disputable"
        );
        trades[id].state = TRADE_STATE.DISPUTE;
    }

    function agreeIndexPrice(uint256 id) public {
        Trade memory t = trades[id];
        require(
            t.buyer == msg.sender,
            "only buyer is able to agree indexPrice"
        );
        if (
            t.state == TRADE_STATE.PRICE_CONFIRMING ||
            t.state == TRADE_STATE.DISPUTE
        ) {
            //reached agreement between buyer and seller, now settle
            if (t.isCall) {
                if (t.indexPrice > t.strike) {
                    //exercise a call option. base token notional goes to buyer,
                    //contra token goes to seller
                    trades[id].state = TRADE_STATE.DELIVERED;
                    require(
                        IERC20(t.contraTokenAdd).transferFrom(
                            msg.sender,
                            t.seller,
                            ((t.notional+t.premium) * t.strike) / (1 ether)
                        ),
                        "failed to exercise"
                    );
                    require(
                        IERC20(t.baseTokenAdd).transfer(t.buyer, t.notional+t.premium),
                        "failed to send notional"
                    );
                } else {
                    trades[id].state = TRADE_STATE.EXPIRED;
                    //option is not exercised, send notional+premium back to seller
                    require(
                        IERC20(t.baseTokenAdd).transfer(
                            t.seller,
                            t.notional + t.premium
                        ),
                        "failed to send back notional+premium"
                    );
                }
            } else {
                if (t.indexPrice < t.strike) {
                    //exercise a put option. contra token notional goes to buyer,
                    //premium+base token goes to seller
                    trades[id].state = TRADE_STATE.DELIVERED;
                    require(
                        IERC20(t.baseTokenAdd).transferFrom(
                            msg.sender,
                            t.seller,
                            ((t.notional+t.premium) * (1 ether)) / t.strike
                        ),
                        "failed to exercise"
                    );
                    require(
                        IERC20(t.contraTokenAdd).transfer(t.buyer, t.notional+t.premium),
                        "failed to send back notional"
                    );
                } else {
                    trades[id].state = TRADE_STATE.EXPIRED;
                    require(
                        IERC20(t.contraTokenAdd).transfer(
                            t.seller,
                            t.notional + t.premium
                        ),
                        "failed to send back notional+premium"
                    );
                }
            }
        } else {
            revert("unable to consent on index price");
        }
    }

    function getTradesFor(address id, bool isBuy)
        public
        view
        returns (Trade[] memory)
    {
        uint256[] memory tradeIds = (isBuy ? buyingTrades : sellingTrades)[id];
        uint256 tradeSize = tradeIds.length;
        Trade[] memory localTrades = new Trade[](tradeSize);
        for (uint256 i = 0; i < tradeSize; i++) {
            localTrades[i] = trades[tradeIds[i]];
        }
        return trades;
    }

    function getTradesBuySell(bool isBuy) public view returns (Trade[] memory) {
        return getTradesFor(msg.sender, isBuy);
    }
    function getTradeById(uint256 tradeId)public view returns(TRADE_STATE,uint256){
        Trade memory t=trades[tradeId];
        return (t.state,t.premium);
    }
}