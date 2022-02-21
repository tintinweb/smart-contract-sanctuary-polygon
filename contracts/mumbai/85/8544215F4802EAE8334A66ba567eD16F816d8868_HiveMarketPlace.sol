/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.4;

interface IERC165 {

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
    */

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC1155 is IERC165 {

    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */

    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
    */

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
    */

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);


    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */

    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
*/

interface IERC20 {

    /**
     * @dev Returns the amount of tokens in existence.
    */

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
    */

    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */

    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
    */

    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
    */

    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
    */ 

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}    

contract HiveMarketPlace {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SignerChanged(address indexed previousSigner, address indexed newSigner);
    event TreasuryFeeChanged(uint8 teamsFee);
    event CharityFeeChanged(uint8 charityFee);
    event TeamsFeeChanged(uint8 teamsFee);
    event HiveTransferrred(address indexed from, address indexed to, uint256 indexed amount);

    //hive Fees
    uint8 public hiveTreasuryFee;
    uint8 public hiveTeamsFee;
    uint8 public hiveCharityFee;
    //hive Authenticators
    address public hiveOwner;
    address public hiveSigner;
    //hiveFee receivers
    address public hiveTreasury;
    address public hiveTeams;
    address public hiveCharity;
    // nonce mapping 
    mapping(uint256 => bool) private usedNonce;

    /* Fee structure */
    struct Fee {
        uint treasuryFee;
        uint teamsFee;
        uint charityFee;
        uint assetFee;
        }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }
    /* buying enum */
    enum buyingType {
        selling,
        buying
    }

    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        buyingType orderType;
        uint amount;
        uint tokenId;
    }

    modifier onlyOwner() {
        require(hiveOwner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    constructor (uint8 _hiveTeamsFee, uint8 _hiveCharityFee, uint8 _hiveTreasuryFee, address _hiveTreasury, address _hiveTeams, address _hiveCharity) {
        hiveTeamsFee = _hiveTeamsFee;
        hiveCharityFee = _hiveCharityFee;
        hiveTreasuryFee = _hiveTreasuryFee;
        hiveOwner = msg.sender;
        hiveSigner = msg.sender;
        hiveTreasury = _hiveTreasury;
        hiveTeams = _hiveTeams;
        hiveCharity = _hiveCharity;
    }
    /** setTreasuryFee is an external function set the newTeamsFee.
      @param  _treasuryFee new sellerFee
      onlyOwner modifier provides authorisation.
      returns the bool value always true;
     */

    function setTreasuryFee(uint8 _treasuryFee) external onlyOwner returns(bool) {
        hiveTreasuryFee = _treasuryFee;
        emit TreasuryFeeChanged(_treasuryFee);
        return true;
    }
    /** setteamsFee is an external function set the newsFee.
      @param _teamsFee new sellerFee
      onlyOwner modifier provides authorisation.
      returns the bool value always true;
     */

    function setTeamsFee(uint8 _teamsFee) external onlyOwner returns(bool) {
        hiveTeamsFee = _teamsFee;
        emit TeamsFeeChanged(_teamsFee);
        return true;
    }

    /** setCharityFee is an external function set the new CharityFee.
      @param _charityFee new sellerFee
      onlyOwner modifier provides authorisation.
      returns the bool value always true;
     */

    function setCharityFee(uint8 _charityFee) external onlyOwner returns(bool) {
        hiveCharityFee = _charityFee;
        emit CharityFeeChanged(_charityFee);
        return true;
    }

    /** transferOwnership is an external function set the newOwner.
      @param newOwner new OwnerAddress
      onlyOwner modifier provides authorisation.
      returns the bool value always true;
     */

    function transferOwnership(address newOwner) external onlyOwner returns(bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(hiveOwner, newOwner);
        hiveOwner = newOwner;
        return true;
    }

    /** changeSigner is an external function set the newSigner.
      @param newSigner new signerAddress
      onlyOwner modifier provides authorisation.
      returns the bool value always true;
     */

    function changeSigner(address newSigner) external onlyOwner returns(bool) {
        require(newSigner != address(0), "Signer: new signer shouldn't be zero");
        emit SignerChanged(hiveSigner, newSigner);
        hiveSigner = newSigner;
        return true;
    }

    /** verifyOrder is an internal pure function that recover the sign message from hash value.
        @param hash contains the hash value that is generated from parent method @isVerifiedOrder
        @param sign struct contains set of parameters in order to V,R,S,Nonce. 
     */

    function verifyOrder(bytes32 hash, Sign calldata sign) internal pure returns(address) {
        return ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), sign.v, sign.r, sign.s);
    }

    /**  isVerifiedOrder is an internal function verifies the order whether approved or not.
        @param order struct contains set of parameters like seller,buyer,tokenId..., etc.
        @param sign struct contains set of parameters in order to V,R,S,Nonce.
        it checks whether the signer is signed or not.
     */

    function isVerifiedOrder(Order memory order, Sign calldata sign) internal view {
        bytes32 hash = keccak256(abi.encodePacked(order.seller, order.buyer, order.erc20Address, order.nftAddress, order.amount, sign.nonce));
        require(hiveSigner == verifyOrder(hash, sign), " sign verification failed");
    }
    /** calculateFee is an internal function takes responciblity for calculating Fees.
        @param sellingPrice selling amount of NFTs.
        it returns the Fee struct that contains the members like assetFee, treasuryFee, teamsFee, charityFee.
     */

    function calculateFees(uint sellingPrice) internal view returns(Fee memory){
        uint treasuryFee;
        uint teamsFee;
        uint charityFee;
        uint assetFee;
        treasuryFee = sellingPrice * hiveTreasuryFee / 1000;
        teamsFee = sellingPrice * hiveTeamsFee / 1000;
        charityFee = sellingPrice * hiveCharityFee / 1000;
        assetFee = sellingPrice - treasuryFee - teamsFee - charityFee;
        return Fee(assetFee, treasuryFee, teamsFee, charityFee);
    }
    /**  
        transferHives is an internal function that takes care about the transfer HIVENFTS.
        @param order struct contains set of parameters like seller,buyer,tokenId..., etc.
        @param fee struct contains set of parameters in order to assetFee, charityFee, teamsFee.

    */
    function transferHives(Order memory order, Fee memory fee) internal virtual {
        
        IERC1155(order.nftAddress).safeTransferFrom(order.seller, order.buyer, order.tokenId, 1,"");

        if(fee.treasuryFee > 0) {
            IERC20(order.erc20Address).transferFrom(order.buyer, hiveTreasury, fee.treasuryFee);
        }
        if(fee.teamsFee > 0) {
            IERC20(order.erc20Address).transferFrom(order.buyer, hiveTeams, fee.teamsFee);
        }
        if(fee.charityFee > 0) {
            IERC20(order.erc20Address).transferFrom(order.buyer, hiveCharity, fee.charityFee);
        }
        IERC20(order.erc20Address).transferFrom (order.buyer, order.seller, fee.assetFee);
    }

    /**  
        excuteOrder excutes the  selling and buying HiveNFTs orders.
        @param order struct contains set of parameters like seller,buyer,tokenId..., etc.
        @param sign struct contains set of parameters in order to V,R,S,Nonce.
        function returns the bool value always true;

    */
    function excuteOrder(Order memory order, Sign calldata sign) external returns(bool) {
        require(!usedNonce[sign.nonce],"Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        isVerifiedOrder(order, sign);
        Fee memory fee = calculateFees(order.amount);
        if(order.orderType == buyingType.selling) order.seller = msg.sender;
        if(order.orderType == buyingType.buying) order.buyer = msg.sender;
        transferHives(order,fee);
        emit HiveTransferrred(order.seller, order.buyer, order.amount);
        return true;
    }
}