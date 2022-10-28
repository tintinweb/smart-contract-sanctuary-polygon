/**
 *Submitted for verification at polygonscan.com on 2022-10-28
*/

// File: xenDaoOwner.sol

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.10;

interface IXenDao {
	function mintNoExpectation() external;
	function transfer(address to, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function wchangeAddress(address _noExpect) external;
    function setFee(uint256 _newFee, uint256 _againFee, uint256 _sendFee) external;
	function stake(uint256 _amount) external;
	function setSendingReward(uint256 _new) external;
	function withdraw() external;
    function harvest() external;
}

interface IXVMC {
	function governor() external view returns (address);
}

interface IGovernor {
	function treasuryWallet() external view returns (address);
    function consensusContract() external view returns (address);
}

interface IConsensus {
	function tokensCastedPerVote(uint256 _forID) external view returns(uint256);
	function totalXVMCStaked() external view returns(uint256);
}

contract DaoOwner {
	IXenDao public immutable xenDao;
	address public immutable xvmc = 0x970ccEe657Dd831e9C37511Aa3eb5302C1Eb5EEe;
	address public feeControl = 0xf16d68c08a05Cd824FC026FeC1191A3ee261c70A;

	constructor(IXenDao _xenDao) {
		xenDao = _xenDao;
	}

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
	

	// mints and sends token to XVMC governance
	function mint() external {
		xenDao.mintNoExpectation();
		xenDao.stake(xenDao.balanceOf(address(this)));
	}

    function harvest() external {
        xenDao.harvest();
        payable(treasury()).transfer(address(this).balance);
    }
	
	function treasury() public view returns (address) {
		return IGovernor(governor()).treasuryWallet();
	}
	
	function governor() public view returns (address) {
		return IXVMC(xvmc).governor();
	}
	
	function votingContract() public view returns (address) {
		return IGovernor(governor()).consensusContract();
	}
	
	function voteCount(uint256 _forId) public view returns(uint256) {
		return IConsensus(votingContract()).tokensCastedPerVote(_forId);
	}
	
	function totalVoting() public view returns(uint256) {
		return IConsensus(votingContract()).totalXVMCStaked();
	}
	
	function changeAddress(address _newAddress) external {
		require(msg.sender == governor() || msg.sender == feeControl);
		xenDao.wchangeAddress(_newAddress);
	}

    function setFee(uint256 _newFee, uint256 _againFee, uint256 _sendFee) external {
        require(msg.sender == governor() || msg.sender == feeControl, "fee control address only");
        xenDao.setFee(_newFee, _againFee, _sendFee);
    }
	
    function setSendingReward(uint256 _sendingReward) external {
        require(msg.sender == governor() || msg.sender == feeControl, "fee control address only");
		xenDao.setSendingReward(_sendingReward);
    }

	function changeFeeAddress(address _new) external {
		require(msg.sender == governor() || msg.sender == feeControl, "fee control address only");
		feeControl = _new;
	}
	
	function withdrawToTreasury() external {
		require(msg.sender == governor() || msg.sender == feeControl, "fee control address only");
		xenDao.mintNoExpectation();
		xenDao.withdraw();
		xenDao.transfer(treasury(), xenDao.balanceOf(address(this)));
        payable(treasury()).transfer(address(this).balance);
	}
	
	function addressToUint256(address _address) public pure returns(uint256) {
		return(uint256(uint160(_address)));
	}
	
	function changeAddressVoting(address _new) external {
		uint256 _contractInUint = addressToUint256(_new);
		uint256 _totalVotes = voteCount(_contractInUint);
		uint256 _totalPower = totalVoting();
		require(_totalVotes >= _totalPower * 4 / 10, "40% allocated voting required");

		xenDao.mintNoExpectation();
		xenDao.withdraw();
		xenDao.transfer(_new, xenDao.balanceOf(address(this)));
		xenDao.wchangeAddress(_new);
        payable(treasury()).transfer(address(this).balance);
	}
}