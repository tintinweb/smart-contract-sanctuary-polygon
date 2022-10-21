/**
 *Submitted for verification at polygonscan.com on 2022-10-21
*/

//SPDX-License-Identifier: NONE
pragma solidity ^0.8.10;

interface IXenDao {
	function mintNoExpectation() external;
	function transfer(address to, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	function changeAddress(address _noExpect) external;
    function setFee(uint256 _newFee, uint256 _againFee) external;
}

interface IXVMC {
	function governor() external view returns (address);
}

interface IGovernor {
	function treasuryWallet() external view returns (address);
}

contract DaoOwner {
	IXenDao public immutable xenDao;
	address public immutable xvmc = 0x970ccEe657Dd831e9C37511Aa3eb5302C1Eb5EEe;
	
	constructor(IXenDao _xenDao) {
		xenDao = _xenDao;
	}

	// mints and sends token to XVMC governance
	function mint() external {
		xenDao.mintNoExpectation();
		require(xenDao.transfer(treasury(), xenDao.balanceOf(address(this))));
	}
	
	function treasury() public view returns (address) {
		return IGovernor(governor()).treasuryWallet();
	}
	
	function governor() public view returns (address) {
		return IXVMC(xvmc).governor();
	}
	
	function changeAddress(address _newAddress) external {
		require(msg.sender == governor(), "decentralized voting only");
		xenDao.changeAddress(_newAddress);
	}

    function setFee(uint256 _newFee, uint256 _againFee) external {
        require(msg.sender == governor(), "decentralized voting only");
        xenDao.setFee(_newFee, _againFee);
    }
}