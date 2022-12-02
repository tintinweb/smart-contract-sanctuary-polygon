/**
 *Submitted for verification at polygonscan.com on 2022-12-02
*/

// SPDX-License-Identifier: SimPL-2.0
// Author:WizzyAng
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
contract auction {
    //拍卖行
    address payable public auctionHouse; 
    mapping(uint256 => string) public baseState;
    
    struct auctionItem{
        string Name;
        string Info;
        uint256 Price;
        uint256 StartTime;//拍卖开始时间的时间戳
        uint256 StateIdx;
        address payable Owner;
        uint256 HighestBid;
        address payable HighestBider;
    }
    
    auctionItem[3] public auctionItems ;

    constructor(address payable  _owner){
        auctionHouse = _owner;
        //初始化baseState
        baseState[0] = "Off shelf";
        baseState[1] = "Under auction";
        baseState[2] = "Had sold";
        //初始化商品信息，拍卖时间，起拍价
        auctionItems[0] = auctionItem("Name0","There is auction0's info",1,block.timestamp,0,0x35a1A713C87335286a89A808588029cc4B154d78,0,0x0000000000000000000000000000000000000000);//
        auctionItems[1] = auctionItem("Name1","There is auction1's info",1,block.timestamp + 60,0,0x35a1A713C87335286a89A808588029cc4B154d78,0,0x0000000000000000000000000000000000000000);//
        auctionItems[2] = auctionItem("Name2","There is auction2's info",1,block.timestamp + 60,0,0x35a1A713C87335286a89A808588029cc4B154d78,0,0x0000000000000000000000000000000000000000);//
    }

    //将auctionItems[pid]上架
    function putOnShelves(uint256 pid) public returns(bool){
        if(auctionItems[pid].StateIdx == 1){
            return true;
        }
        //时间验证
        require(block.timestamp >= auctionItems[pid].StartTime,"auction error:It's not the time");
        //状态验证
        require(auctionItems[pid].StateIdx == 0,"auction error: this item cannot be listd");
        //最低价验证
        require(auctionItems[pid].Price >= 1,"auction error: the price is too cheap");//
        //状态更新
        auctionItems[pid].StateIdx = 1;
        return true;
    }

    //设置auctionItems[pid].StartTime为当前时间戳+aftermin*60
    function setStartTime(uint256 pid, uint256 aftermin) public returns(bool){
        //权限验证
        require(msg.sender == auctionHouse,"auction error: no permission");
        //状态验证
        require(auctionItems[pid].StateIdx == 0,"auction error: this item cannot be listd");
        auctionItems[pid].StartTime = block.timestamp + aftermin * 60;
        return true;
    }


    //设置auctionItems[pid].price
    function setPrice(uint256 pid, uint256 price) public returns(bool){
        //权限验证
        require(msg.sender == auctionHouse,"auction error: no permission");
        //状态验证
        require(auctionItems[pid].StateIdx == 0,"auction error: this item cannot be listd");
        //最低价验证
        require(price >= 1,"auction error: the price is too cheap");//
        auctionItems[pid].Price = price;
        return true;

    }


    //验证auctionItemd[pid]是否可拍,若超时
    //1.有人拍，则结算并更新状态
    //2.无人拍，则更新状态进入下一轮拍卖
    function verifyBid(uint256 pid) private returns(bool){
        //如果 当前时间-起拍时间 大于 10min
        if(block.timestamp - auctionItems[pid].StartTime >= 600){
            //如果无人拍卖,商品进入新一轮的拍卖
            if(auctionItems[pid].HighestBider == 0x0000000000000000000000000000000000000000){
                putOnShelves(pid);
                return true;
            }
            else{
                require(auctionItems[pid].StateIdx == 1,"auction error: Settled");
                auctionItems[pid].StateIdx = 2;
                //买家向卖家转钱
                auctionItems[pid].Owner.transfer(auctionItems[pid].HighestBid);
                //卖家将商品的Owner设为买家
                auctionItems[pid].Owner = auctionItems[pid].HighestBider;
                return false;
            }
        }
        return true;
    }

    //bid
    function bid(uint256 pid) public payable returns(bool){
        //达到时间到自动上架的效果
        require(putOnShelves(pid));
        //时间验证并修改结算
        require(verifyBid(pid),"auction error: this item had sold");
        //状态验证
        require(auctionItems[pid].StateIdx == 1,"auction error: this item cannot be bid");
        //价格验证
        require(auctionItems[pid].HighestBid < msg.value,"auction error: your price must more than the maxPrice");
        //返还原始最高出价
        if(auctionItems[pid].HighestBider != 0x0000000000000000000000000000000000000000)
            auctionItems[pid].HighestBider.transfer(auctionItems[pid].HighestBid);
        //更新最高出价
        auctionItems[pid].HighestBider = msg.sender;
        auctionItems[pid].HighestBid = msg.value;
        return true;
    }

    function settlement(uint256 pid) public returns(string memory){
        require(msg.sender == auctionHouse, "auction error: no permission");
        if(verifyBid(pid)){
            return "cannot settlement";
        }
        else{
            return "settlement ok";
        }
        
    }
    //查看auctionItems[pid]的信息
    function queryAuctionItems(uint256 pid) public view returns(string memory Name,string memory Info,uint256 Price,uint256 StartTime,uint256 StateIdx,address payable Owner,uint256 HighestBid,address payable HighestBider){
        require(pid >= 0 && pid <= 2,"pid out of range");
        auctionItem memory aipid = auctionItems[pid];
        return (aipid.Name,aipid.Info,aipid.Price,aipid.StartTime,aipid.StateIdx,aipid.Owner,aipid.HighestBid,aipid.HighestBider);
    }
    //查看baseState[idx]所代表的意义
    function queryBaseState(uint256 idx) public view returns(string memory State){
        require(idx >= 0 && idx <= 2,"idx out of range");
        string memory st = baseState[idx];
        return st;
    }
    //查询拍卖行的地址
    function queryAuctionHouse() public view returns(address AuctionHouseAddr){
        return auctionHouse;
    }
}