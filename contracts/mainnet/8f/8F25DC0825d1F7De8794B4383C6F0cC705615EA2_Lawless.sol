// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @author Ademar Gonzalez

import './ERC721.sol';
import './SafeERC20.sol';
import "./IERC2981.sol";
import './Ownable.sol';
import './Strings.sol';
import './WithLimitedSupply.sol';


contract Lawless is ERC721, IERC2981, Ownable, WithLimitedSupply {
	using Strings for uint256;

	/*
	 * Private Variables
	 */
	uint256 private constant NUMBER_OF_IMAGES = 68; 
	uint256 private constant NUMBER_OF_COPIES = 25; 

	enum SalePhase {
		Locked,
		PublicSale
	}

	string private _tokenBaseURI = "https://cloud.lawless.art/narcicity/";

    address private _payoutAddress = address(0x00495e95FD936fF0A0eCA63C6a58C463E37029Ce);


	/*
	 * Public Variables
	 */

	SalePhase public phase = SalePhase.Locked;

    // Deployed on Polygon this mean MATIC currency
	uint256 public mintPrice = 50 ether;
	
    // Maps token Ids to token URIs
    mapping (uint256 => uint256) private _tokenURIs;

	event PaymentReceived(address from, uint256 amount);

	/*
	 * Constructor
	 */
	constructor()
		ERC721('Lawless Narcicity Collection', 'NARCICITY')
        WithLimitedSupply(NUMBER_OF_IMAGES*NUMBER_OF_COPIES)
	{

	}

	receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

	// ======================================================== Owner Functions

	/// Adjust the mint price
	/// @dev modifies the state of the `mintPrice` variable
	/// @notice sets the price for minting a token
	/// @param newPrice_ The new price for minting
	function adjustMintPrice(uint256 newPrice_) external onlyOwner {
		mintPrice = newPrice_;
	}

    /// Changes the payout address
	/// @dev modifies the state of the `_payoutAddress` variable
	/// @notice sets the payout address
	/// @param newPayoutaddress The new payout address
	function changePayoutAddress(address newPayoutaddress) external onlyOwner {
		_payoutAddress = newPayoutaddress;
	}

	/// Advance Phase
	/// @dev Advance the sale phase state
	/// @notice Advances sale phase state incrementally
	function enterPhase(SalePhase phase_) external onlyOwner {
		phase = phase_;
	}


	/// Disburse payment to the payout address
	/// @dev transfers full amount of ETH to payout address
	function disburse() external onlyOwner {
		makePaymentTo(_payoutAddress);
	}

    /// Disburse ERC20 token balance to the payout address
	/// @dev transfers full amount of ERC20 token to the payout address
	function disburse(IERC20 token) external onlyOwner {
		SafeERC20.safeTransfer(token, _payoutAddress, token.balanceOf(address(this)));
	}

	/// Make a payment
	/// @dev internal fn called by `disbursePayments` to send Ether to an address
	function makePaymentTo(address address_) private {
		(bool success, ) = address_.call{value: address(this).balance}('');
		require(success, 'Transfer failed.');
	}

	// ======================================================== External Functions

	/// Public minting open to all
	/// @notice mints tokens to the sender's address
	function mint()
		external
		payable
		validateEthPayment()
		returns (uint256)
	{
		require(phase == SalePhase.PublicSale, 'Public sale is not active');
		
        uint256 newItemId = super.nextToken();

        _mint(msg.sender, newItemId);

        // Map tokenId to tokenURI
        uint256 tokenURIIndex = newItemId % NUMBER_OF_IMAGES;

        _tokenURIs[newItemId] = tokenURIIndex;

		return newItemId;
	}

	/// Public minting open to all
	/// @notice mints tokens to the sender's address
	function ownerMint()
		external
		onlyOwner
		returns (uint256)
	{
		uint256 newItemId = super.nextToken();

        _mint(msg.sender, newItemId);

        // Map tokenId to tokenURI
        uint256 tokenURIIndex = newItemId % NUMBER_OF_IMAGES;

        _tokenURIs[newItemId] = tokenURIIndex;

		return newItemId;
	}

		// ======================================================== Overrides

       

	/// Return the tokenURI for a given ID
	/// @dev overrides ERC721's `tokenURI` function and returns either the `_tokenBaseURI` or a custom URI
	/// @notice reutrns the tokenURI using the `_tokenBase` URI if the token ID hasn't been suppleid with a unique custom URI
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		
        return string(abi.encodePacked(_tokenBaseURI, Strings.toString(_tokenURIs[tokenId] + 1),'.json'));

    }

    /// OpeanSea uses this method to query for royalty fees
	// This metadata is about the contract and not the individual NFTs
	function contractURI() public pure returns (string memory) {
        return "https://cloud.lawless.art/narcicity/contract-metadata.json";
    }
    
	/// Implements EIP-2981
	function royaltyInfo(uint256, uint256 value)
        external
		view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (value * 10) / 100);
    }

	/// override supportsInterface because two base classes define it
	/// @dev See {IERC165-supportsInterface}.
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC721,IERC165)
		returns (bool)
	{
		return
			ERC721.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId ;
	}

    // ======================================================== Modifiers

	/// Modifier to validate Eth payments on payable functions
	/// @dev compares the product of the state variable `_mintPrice` and supplied `count` to msg.value
	modifier validateEthPayment() {
		require(
			mintPrice <= msg.value,
			'Ether value sent is not correct'
		);
		_;
	}
} // End of Contract