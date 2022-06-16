/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: AuctionFactory.sol

pragma solidity 0.8.11;

// import './Auction.sol';


contract AuctionFactory is Pausable {

    address public addrAdmin;
    address[] private addrPayTokens;
    address[] private _auctions;
    address private commissionWallet;
	uint256 private commissionPercent; // part of 1000: example 2.5% => value 25
	mapping(address=>bool) public acceptableNfts;

    // event AuctionCreated(address indexed auctionContract, address indexed owner, uint256 startPrice, Type auctionType, uint256 numAuctions);
    event AdminChanged(address indexed newAdmin);
    event CommissionPercentChanged(uint256 newCommissionPercent);
    event CommissionWalletChanged(address indexed newWallet);

    constructor(
        address _admin,
        address[] memory _payTokens,
        address[] memory _acceptableNfts,
		address _commissionWallet,
		uint256 _commissionPercent
    ) {
        require(_commissionPercent < 1000, "Only 100% + 1 decimal char");
        addrAdmin = _admin;
        addrPayTokens = _payTokens;
		commissionPercent = _commissionPercent;
		commissionWallet = _commissionWallet;
		for (uint256 i=0; i<_acceptableNfts.length; i++){
			address nftAddr = _acceptableNfts[i];
			acceptableNfts[nftAddr] = true;
		}
    }

    function changeAdmin(address newAdminAddress) external onlyAdmin {
        require(newAdminAddress != address(0), "No zero address");
        addrAdmin = newAdminAddress;
        emit AdminChanged(addrAdmin);
    }

	function changeCommissionPercent(uint256 _newPercent) external onlyAdmin {
        require(_newPercent < 1000, "Only 100% + 1 decimal char");
        commissionPercent = _newPercent;
        emit CommissionPercentChanged(commissionPercent);
    }

	function changeCommissionWallet(address _newWallet) external onlyAdmin {
        require(_newWallet != address(0), "No zero address");
        commissionWallet = _newWallet;
        emit CommissionWalletChanged(commissionWallet);
    }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function addAcceptableNft(address acceptableNft) external onlyAdmin {
        acceptableNfts[acceptableNft] = true;
    }

    function removeAcceptableNft(address acceptableNft) external onlyAdmin {
        require(isAcceptableNft(acceptableNft), "ERROR_NOT_ACCEPTABLE_NFT");
		acceptableNfts[acceptableNft] = false;
    }

    function isAcceptableNft(address acceptableNft) internal view returns(bool) {
        return acceptableNfts[acceptableNft];
    }

    function addPayToken(address payToken) external onlyAdmin {
        if(!isPayToken(payToken)) {
            addrPayTokens.push(payToken);
        }
    }

    function removePayToken(address payToken) external onlyAdmin {
        require(isPayToken(payToken), "ERROR_NOT_ACCEPTABLE_TOKEN");

        for(uint256 i = 0; i < addrPayTokens.length; i++) {
            if(payToken == addrPayTokens[i]) {
				addrPayTokens[i] = addrPayTokens[addrPayTokens.length-1];
				addrPayTokens.pop();
            }
        }
    }

    function isPayToken(address payToken) internal view returns(bool) {
        for(uint256 i = 0; i < addrPayTokens.length; i++) {
            if(payToken == addrPayTokens[i]) {
                return true;
            }
        }

        return false;
    }

    function getPayTokens() external view returns(address[] memory) {
        return addrPayTokens;
    }

    // function createAuction(
    //     uint256 duration, // seconds
    //     uint256 buyValue, // start/sell price
    //     address payToken,
    //     address nftToken,
    //     uint256 nftId,
    //     Type _type
    // )
    // external
    // whenNotPaused
    // {
    //     require(!paused(), "ERROR_PAUSE");
    //     require(isPayToken(payToken), "ERROR_NOT_ACCEPTABLE_TOKEN");
    //     require(isAcceptableNft(nftToken), "ERROR_NOT_ACCEPTABLE_NFT");

    //     Auction newAuction = new Auction(
    //         _msgSender(),
    //         addrAdmin,
    //         duration,
    //         nftToken,
    //         nftId,
    //         payToken,
    //         buyValue,
    //         _type,
	// 		commissionWallet,
	// 		commissionPercent
    //     );
    //     _auctions.push(address(newAuction));

    //     emit AuctionCreated(address(newAuction), _msgSender(), buyValue, _type, _auctions.length);
    // }

    function allAuctions() public view returns (address[] memory auctions) {
        return auctions = _auctions;
    }

    modifier onlyAdmin {
        require(_msgSender() == addrAdmin, "Only admin");
        _;
    }

}