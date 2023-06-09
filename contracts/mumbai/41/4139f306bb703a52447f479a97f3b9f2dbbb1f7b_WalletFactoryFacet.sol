// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./WalletFacet.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";

error WalletFactoryFacet__AlreadyHaveMetadev3Wallet();

contract WalletFactoryFacet {
    AppStorage s;

	event WalletCreated(address indexed owner, address indexed metadev3Wallet);

	function createWallet() external {
		if (s.walletToMetadev3Wallet[msg.sender] != address(0)) revert WalletFactoryFacet__AlreadyHaveMetadev3Wallet();
		WalletFacet newWallet = new WalletFacet(payable(msg.sender));
		s.walletToMetadev3Wallet[msg.sender]= address(newWallet);
		emit WalletCreated(msg.sender, address(newWallet));
	}

	function getWallet(address _owner) external view returns (address) {
		return s.walletToMetadev3Wallet[_owner];
	}
	function testUseless() external view returns (uint256) {
		return s.totalSupply;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/IERC20.sol";

error WalletFacet__isNotOwner();
error WalletFacet__InvalidTokenAddress();

contract WalletFacet {
	address payable public owner;

	constructor(address payable _owner) {
		owner = _owner;
	}

	receive() external payable {}

	modifier isOwner() {
		if (msg.sender != owner) revert WalletFacet__isNotOwner();
		_;
	}
	modifier isValidERC20(address _token) {
		if (_token == address(0)) revert WalletFacet__InvalidTokenAddress();
		_;
	}
	
	function send (address payable _to, uint _amount) external isOwner {
		_to.transfer(_amount);
	}

	function withdraw(uint _amount) external isOwner {
		payable(msg.sender).transfer(_amount);
	}

	function withdrawERC20(address _token, uint _amount) external isOwner isValidERC20(_token) {
		IERC20 token = IERC20(_token);
		token.transfer(msg.sender, _amount);
	}

	function getETHBalance() external view returns (uint) {
		return address(this).balance;
		// will give the balance in eth
	}

	function getERC20Balance(address _token) external view isValidERC20(_token) returns (uint) {
		IERC20 token = IERC20(_token);
		return token.balanceOf(address(this));
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

struct AppStorage {
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => address) walletToMetadev3Wallet;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}