/**
 *Submitted for verification at polygonscan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
interface IXEN {
    function balanceOf(address account) external view returns (uint256);

    function burn(address user, uint256 amount) external;
}

interface IXD {
	function mintNoExpectation() external;
	function transfer(address to, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
    function setFee(uint256 _newFee, uint256 _againFee, uint256 _sendFee) external;
	function stake(uint256 _amount) external;
	function setSendingReward(uint256 _new) external;
	function withdraw() external;
    function harvest() external;
    function wchangeAddress(address _noExpect) external;
    function mint(address _to, uint256 _amount) external;
}

interface IXVMC {
	function governor() external view returns (address);
}

interface IBurnRedeemable {
    event Redeemed(
        address indexed user,
        address indexed xenContract,
        address indexed tokenContract,
        uint256 xenAmount,
        uint256 tokenAmount
    );

    function onTokenBurned(address user, uint256 amount) external;
}


contract XenDAOBurner {
    IXEN public immutable XEN;
    IXD public immutable XD;
    IXVMC public immutable XVMC = IXVMC(0x970ccEe657Dd831e9C37511Aa3eb5302C1Eb5EEe);
    uint256 public immutable burnPerBatch = 1e6 * 1e18;
    uint256 public rewardPerBatch = 1e7 * 1e18;
    uint256 public immutable protocolFee; //roughly 20% of XEN value burned

    uint256 public lastRewardUpdate;

    address public payoutAddress = 0xA2e4728c89D6dCFc93dF4b2b438E49da823Fe181; //XVMC buyback contract

    constructor(IXEN _xen, IXD _xd, uint256 _fee) {
        XEN = _xen;
        XD = _xd;
        protocolFee = _fee;
        lastRewardUpdate = block.timestamp + 3 days;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function burnXEN(uint256 _batches) external payable {
        uint256 _fee = _batches * protocolFee;
        require(msg.value == _fee, "insufficient fee");
        payFee(_fee);

        uint256 _burnAmount = _batches * burnPerBatch;
        require(XEN.balanceOf(msg.sender) >= _burnAmount, "XenDAOBurner: Insufficient XEN tokens for burn");

        XEN.burn(msg.sender, _burnAmount);
        XD.mint(msg.sender, _batches * rewardPerBatch);
    }

    function burnXENref(uint256 _batches, address _ref) external payable {
        require(msg.sender != _ref, "XenDAOBurner: cant refer self");

        uint256 _fee = _batches * protocolFee;
        require(msg.value == _fee, "insufficient fee");
        payFee(_fee);

        uint256 _burnAmount = _batches * burnPerBatch;
        require(XEN.balanceOf(msg.sender) >= _burnAmount, "XenDAOBurner: Insufficient XEN tokens for burn");

        XEN.burn(msg.sender, _burnAmount);
        XD.mint(msg.sender, _batches * rewardPerBatch * 115 / 100);
        XD.mint(_ref, _batches * rewardPerBatch * 15 / 100);
    }

    function mintXDreserves() external {
        XD.mintNoExpectation();
    }

    function doAction() external {
        XD.mintNoExpectation();
        XD.stake(XD.balanceOf(address(this)));
        XD.harvest();
        payable(payoutAddress).transfer(address(this).balance);
    }

    function harvest() external {
        XD.harvest();
        payable(payoutAddress).transfer(address(this).balance);
    }

    function reduceRewards() external {
        require(block.timestamp > lastRewardUpdate + 1 days, "XenDAOBurner: Must wait atleast 24hours");
        rewardPerBatch = rewardPerBatch * 99 / 100;
        lastRewardUpdate = block.timestamp;
    }

    function changePayoutAddress(address _new) external {
        require(msg.sender == XVMC.governor(), "decentralized voting only");
        payoutAddress = _new;
    }

    function transferXD(address _to) external {
        require(msg.sender == XVMC.governor(), "decentralized voting only");
        XD.transfer(_to, XD.balanceOf(address(this)));
    }
    
    /**
        @dev confirms support for IBurnRedeemable interfaces
    */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == type(IBurnRedeemable).interfaceId;
    }

    function payFee(uint256 amount) internal {
        (bool sent, ) = payable(address(XD)).call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}