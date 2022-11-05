// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ReentrancyGuard } from "lib/solmate/src/utils/ReentrancyGuard.sol";

/**
					███████╗ ████████╗ ██████╗  ███╗   ███╗ ███████╗
					██╔════╝ ╚══██╔══╝ ╚════██╗ ████╗ ████║ ╚══███╔╝
					███████╗    ██║     █████╔╝ ██╔████╔██║   ███╔╝
					╚════██║    ██║     ╚═══██╗ ██║╚██╔╝██║  ███╔╝
					███████║    ██║    ██████╔╝ ██║ ╚═╝ ██║ ███████╗
					╚══════╝    ╚═╝    ╚═════╝  ╚═╝     ╚═╝ ╚══════╝
 
 * @title St3mz
 * @notice NFT contract based on the ERC1155 standard, but adapted to be transferable just once.
 * 		   The minter sets the supply and unit price for the token.
 * 		   The token can be bought by anyone, but cannot be transfered to another address afterwards.
 */
contract St3mz is ReentrancyGuard {
	/*//////////////////////////////////////////////////////////////
                                 CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

	error St3mz__AmountZero();
	error St3mz__PriceZero();
	error St3mz__EmptyUri();
	error St3mz__AmountNotAvailable();
	error St3mz__InvalidValueSent();
	error St3mz__BalanceZero();
	error St3mz__TransferFailed();

	/*//////////////////////////////////////////////////////////////
                             EVENTS
    //////////////////////////////////////////////////////////////*/

	event Mint(
		address indexed minter,
		uint256 id,
		string uri,
		uint256 supply,
		uint256 price
	);

	event Buy(address indexed buyer, uint256 id, uint256 amount);

	/*//////////////////////////////////////////////////////////////
                             CONSTANTS
    //////////////////////////////////////////////////////////////*/

	string public constant name = "St3mz NFT";
	string public constant symbol = "ST3MZ";

	/*//////////////////////////////////////////////////////////////
                             STORAGE
    //////////////////////////////////////////////////////////////*/

	mapping(uint256 => address) public minter;
	mapping(uint256 => uint256) public price;
	mapping(uint256 => uint256) public supply;
	mapping(uint256 => uint256) public available;
	mapping(address => mapping(uint256 => uint256)) public balanceOf;
	mapping(address => uint256) public withdrawableBalance;
	mapping(uint256 => string) private _uris;
	uint256 private _ids;

	/*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

	function uri(uint256 id_) external view returns (string memory) {
		return _uris[id_];
	}

	function totalTokens() external view returns (uint256) {
		return _ids;
	}

	function supportsInterface(bytes4 interfaceId_)
		external
		pure
		returns (bool)
	{
		return
			interfaceId_ == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
			interfaceId_ == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
	}

	/*//////////////////////////////////////////////////////////////
                             LOGIC
    //////////////////////////////////////////////////////////////*/

	function mint(
		string calldata uri_,
		uint256 amount_,
		uint256 price_
	) external {
		if (amount_ == 0) revert St3mz__AmountZero();
		if (price_ == 0) revert St3mz__PriceZero();
		if (bytes(uri_).length == 0) revert St3mz__EmptyUri();

		uint256 id = ++_ids;
		_uris[id] = uri_;
		supply[id] = amount_;
		available[id] = amount_;
		minter[id] = msg.sender;
		price[id] = price_;

		emit Mint(msg.sender, id, uri_, amount_, price_);
	}

	function buy(uint256 id_, uint256 amount_) external payable nonReentrant {
		if (amount_ == 0) revert St3mz__AmountZero();
		if (available[id_] < amount_) revert St3mz__AmountNotAvailable();
		if (msg.value == 0 || msg.value != price[id_] * amount_)
			revert St3mz__InvalidValueSent();

		address minter_ = minter[id_];
		available[id_] -= amount_;
		balanceOf[msg.sender][id_] += amount_;
		(bool ok, ) = minter_.call{ value: msg.value }("");
		if (!ok) withdrawableBalance[minter_] += msg.value;

		emit Buy(msg.sender, id_, amount_);
	}

	function withdraw() external {
		uint256 balance = withdrawableBalance[msg.sender];
		if (balance == 0) revert St3mz__BalanceZero();
		withdrawableBalance[msg.sender] = 0;
		(bool ok, ) = msg.sender.call{ value: balance }("");
		if (!ok) revert St3mz__TransferFailed();
	}
}