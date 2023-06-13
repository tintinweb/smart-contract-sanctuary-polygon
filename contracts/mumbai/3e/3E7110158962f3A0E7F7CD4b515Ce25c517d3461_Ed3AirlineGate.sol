// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IEd3LoyaltyPoints.sol";
import "./IEd3AirTicketNFT.sol";

// @title Ed3航空公司服务窗口，用于用于购买机票并发放积分，同时提供接口让管理员可以转移购买机票的资金。
contract Ed3AirlineGate {
    address payable public ed3TicketNFTAddress;
    address public ed3LoyaltyPointsAddress;
    uint256 public immutable POINTS_PER_TICKET;

    /**
     * @notice 航空公司服务窗口构造函数
     * @param _ed3LoyaltyPointsAddress 积分地址
     * @param _ed3TicketNFTAddress NFT机票地址
     * @param _pointsPerTicket 设置积分兑换优惠券比例
     */
    constructor(address _ed3LoyaltyPointsAddress, address payable _ed3TicketNFTAddress, uint256 _pointsPerTicket) {
        ed3LoyaltyPointsAddress = _ed3LoyaltyPointsAddress;
        ed3TicketNFTAddress = _ed3TicketNFTAddress;
        POINTS_PER_TICKET = _pointsPerTicket;
    }

    /**
     * @notice 购买机票、获取积分的函数
     * @param _to 获得机票和积分的地址
     */
    function mint(address _to) external payable {
        uint256 mintPrice = IEd3AirTicketNFT(ed3TicketNFTAddress).mintPrice();
        require(msg.value >= mintPrice, "Insufficient funds");
        uint256 maxSupply = IEd3AirTicketNFT(ed3TicketNFTAddress).maxSupply();
        uint256 totalSupply = IEd3AirTicketNFT(ed3TicketNFTAddress).totalSupply();
        require(maxSupply > totalSupply, "tickets sold out");
        // 购买机票NFT
        IEd3AirTicketNFT(ed3TicketNFTAddress).mint{ value: msg.value }(_to);
        // 每次购买机票后可以得到 POINTS_PER_TICKET 积分
        IEd3LoyaltyPoints(ed3LoyaltyPointsAddress).mint(_to, POINTS_PER_TICKET);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IEd3AirTicketNFT {
    function mint(address _to) external payable;

    function maxSupply() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function mintPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IEd3LoyaltyPoints {
    function mint(address _to, uint256 _mintTokenNumber) external;
}