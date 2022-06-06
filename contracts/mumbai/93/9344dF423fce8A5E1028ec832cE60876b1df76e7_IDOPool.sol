// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./interfaces/IPoolFactory.sol";
import "./interfaces/ITicket.sol";
import "./extensions/KLAYDAOWhitelist.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract IDOPool is Ownable, ReentrancyGuard, Pausable, KLAYDAOWhitelist {

    // bytes32 keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;

    // // address of vrfCoord
    // address public vrfCoord = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;

    // // address of Link token
    // address public linkAddr = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;

    // The token to buy ticket
    address public USDC;

    // The token being sold
    address public token; 

    // The ticket to join ido
    address public ticket;

    // Address where funds are collected
    address public fundingWallet;

    // Timestamps when token started to sell
    uint256 public openTime = block.timestamp;

    // Timestamps when token stopped to sell
    uint256 public closeTime;

    // Amount of token sold
    uint256 public tokenSold = 0;

    // Number of token user purchased
    mapping(address => uint256) public userPurchased;

    // Number of ticket user purchased/minted
    mapping(uint256 => mapping(address => uint256)) public userTicket;


    // Pool extensions
    bool public useWhitelist = true;

    // Init
    bool public init;

    // -----------------------------------------
    // Lauchpad Starter's event
    // -----------------------------------------
    event PoolCreated(
        address token,
        uint256 openTime,
        uint256 closeTime,
        address offeredCurrency,
        address wallet,
        address owner
    );

    event TokenPurchaseByToken(
        address indexed purchaser,
        address indexed beneficiary,
        address token,
        uint256 value,
        uint256 amount
    );
    event RefundedIcoToken(address wallet, uint256 amount);
    event SetPoolExtentions(bool _whitelist);
    event UpdateRoot(bytes32 _root);
    event SetCloseTime(uint256 _closeTime);
    event SetOpenTime(uint256 _openTime);
    event MintTicket(address indexed _to, uint256 _totalStaked, uint256 _id, uint256 _quantity);
    event MintTicketBatch(address indexed _to, uint256 _totalStaked, uint256[] _id, uint256[] _quantity);
    event BuyTicket(address indexed _to, uint256 _amount, uint256 _id, uint256 _quantity);
    event BuyTicketBatch(address indexed _to, uint256 _amount, uint256[] _id, uint256[] _quantity);
    event SwapToToken(address indexed _user, uint256 _amountIDOtoken, uint256 _amountUSDC, uint256 _idTicket, uint256 _totalTicket);
    event SwapToTokenBatch(address indexed _user, uint256 _amountIDOtoken, uint256 _amountUSDC, uint256[] _idTicket, uint256[] _totalTicket);
 
    // -----------------------------------------
    // Red Kite external interface
    // -----------------------------------------

    // constructor() VRFConsumerBase(vrfCoord, linkAddr) {
    //     fee = 0.1 * 10**18;
    // }

    /**
     * @dev fallback function
     */
    fallback() external {
        revert();
    }

    /**
     * @dev fallback function
     */
    receive() external payable {
        revert();
    }

    /**
     * @param _token Address of the token being sold
     * @param _duration Duration of ICO Pool
     * @param _openTime When ICO Started
     * @param _usdc Address of offered token
     * @param _wallet Address where collected funds will be forwarded to
     */
    function initialize(
        address _token,       
        address _usdc,
        address _wallet,
        address _ticketAddress,
        uint256 _openTime,
        uint256 _duration
    ) external {
        require(init == false, "POOL::INITIALIZED");

        // USDC = IERC20(_usdc);
        // token = IERC20(_token);
        // ticket = ITicket(_ticketAddress);


        USDC = _usdc;
        token = _token;
        ticket = _ticketAddress;
        openTime = _openTime;
        closeTime = _openTime + _duration;
        fundingWallet = _wallet;
        
        _transferOwnership(tx.origin);

        init = true;

        emit PoolCreated(
            _token,
            _openTime,
            closeTime,
            _usdc,
            _wallet,
            tx.origin
        );
    }

    /**
     * @notice Owner add root to verify.
     * @param _root root of merkle tree
     */
    function updateRoot(bytes32 _root) external onlyOwner {
        root = _root;

        emit UpdateRoot(_root);
    }

    /**
     * @notice Owner can set the close time (time in seconds). User can buy before close time.
     * @param _closeTime Value in uint256 determine when we stop user to by tokens
     */
    function setCloseTime(uint256 _closeTime) external onlyOwner {
        require(_closeTime >= block.timestamp, "POOL::INVALID_TIME");
        closeTime = _closeTime;

        emit SetCloseTime(_closeTime);
    }

    /**
     * @notice Owner can set the open time (time in seconds). User can buy after open time.
     * @param _openTime Value in uint256 determine when we allow user to by tokens
     */
    function setOpenTime(uint256 _openTime) external onlyOwner {
        openTime = _openTime;

        emit SetOpenTime(_openTime);
    }

    /**
     * @notice Owner can set extentions.
     * @param _whitelist Value in bool. True if using whitelist
     */
    function setPoolExtentions(bool _whitelist) external onlyOwner {
        useWhitelist = _whitelist;

        emit SetPoolExtentions(_whitelist);
    }

    // function mintTicket(
    //     address _to,
    //     uint256 _totalStaked,
    //     uint256 _id,
    //     uint256 _quantity,
    //     bytes memory _data,
    //     bytes32[] memory proof
    // ) public whenNotPaused {

    //     require(_validPurchase(), "POOL::ENDED");
    //     require(_quantity > 0, "POOL::CANT MINT 0 TICKET");
    //     require(_totalStaked > 0, "POOL::TOTAL STAKE ZERO");
    //     require(_to != address(0), "POOL::ZERO ADDRESS");
    
    //     require(_verifyMintTicket(_to, _totalStaked, _id, _quantity, proof), "POOL:INVALID_SIGNATURE");

    //     ITicket(ticket).mint(address(this), _id, _quantity, _data);

    //     userTicket[_id][_to] += _quantity;
        
    //     emit MintTicket(_to, _totalStaked, _id, _quantity);
    // }

    function mintTicketBatch(
        address _to,
        uint256 _totalStaked,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data,
        bytes32[] memory proof
    ) public whenNotPaused {

        require(_validPurchase(), "POOL::ENDED");
        require(_totalStaked > 0, "POOL::TOTAL STAKE ZERO");
        require(_to != address(0), "POOL::ZERO ADDRESS");
    
        require(_verifyMintTicketBatch(_to, _totalStaked, _ids, _quantities, proof), "POOL:INVALID_MERKLE");

        ITicket(ticket).mintBatch(address(this), _ids, _quantities, _data);

        for (uint256 i = 0; i < _ids.length; i++) {
            userTicket[_ids[i]][_to] += _quantities[i];
        }
        
        
        emit MintTicketBatch(_to, _totalStaked, _ids, _quantities);
    }

    // function buyTicket(
    //     address _to,
    //     uint256 _amount,
    //     uint256 _id,
    //     uint256 _quantity,
    //     bytes memory _data,
    //     bytes32[] memory proof
    // ) public whenNotPaused {

    //     require(_validPurchase(), "POOL::ENDED");
    //     require(_quantity > 0, "POOL::CANT MINT 0 TICKET");
    //     require(_amount > 0, "POOL::DONT HAVE ENOUGH TOKEN TO BUY TICKET");
    //     require(_to != address(0), "POOL::CANT MINT 0 TICKET");

    //     _verifyAllowance(msg.sender, _amount);

    //     require(_verifyMintTicket(_to, _amount, _id, _quantity, proof), "POOL:INVALID_MERKLE");

    //     _forwardTokenFunds(_amount);

    //     ITicket(ticket).mint(address(this), _id, _quantity, _data);

    //     userTicket[_id][_to] += _quantity;

    //     emit BuyTicket(_to, _amount, _id, _quantity);
    // }

    function buyTicketBatch(
        address _to,
        uint256 _amount,
        uint256[] memory _ids,
        uint256[] memory _quantities,
        bytes memory _data,
        bytes32[] memory proof
    ) public whenNotPaused {

        require(_validPurchase(), "POOL::ENDED");
        require(_amount > 0, "POOL::DONT HAVE ENOUGH TOKEN TO BUY TICKET");
        require(_to != address(0), "POOL::CANT MINT 0 TICKET");

        _verifyAllowance(msg.sender, _amount);

        require(_verifyMintTicketBatch(_to, _amount, _ids, _quantities, proof), "POOL:INVALID_MERKLE");

        _forwardTokenFunds(_amount);

        ITicket(ticket).mintBatch(address(this), _ids, _quantities, _data);

        for (uint256 i = 0; i < _ids.length; i++) {
            userTicket[_ids[i]][_to] += _quantities[i];
        }

        emit BuyTicketBatch(_to, _amount, _ids, _quantities);
    }


    // function swapToToken(
    //     address _user, 
    //     uint256 _amountIDOtoken, 
    //     uint256 _amountUSDC, 
    //     uint256 _idTicket, 
    //     uint256 _totalTicket,
    //     bytes32[] memory proof
    // ) external whenNotPaused {

    //     require(_verifyResult(_user, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket, proof), "POOL:INVALID_MERKLE");

    //     // user(win or not), _amountIDOtoken, _amountUSDC, _idToken, _amountWinTickets, _amountLoseTickets, 

    //     if (_amountIDOtoken > 0) {
    //         _deliverTokens(_user, _amountIDOtoken);
    //     }

    //     if (_amountUSDC > 0) { 
    //         IERC20(USDC).transfer(_user, _amountUSDC);
    //     }

    //     _updatePurchasingState(_amountIDOtoken);
    
    //     burnTicket(address(this), _idTicket, _totalTicket);

    //     userTicket[_idTicket][msg.sender] -= _totalTicket;
        
    //     emit SwapToToken(_user, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket);
    // }

    function swapToTokenBatch(
        address _user, 
        uint256 _amountIDOtoken, 
        uint256 _amountUSDC, 
        uint256[] memory _idTicket, 
        uint256[] memory _totalTicket,
        bytes32[] memory proof
    ) external whenNotPaused {

        require(_verifyResultBatch(_user, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket, proof), "POOL:INVALID_MERKLE");

        // user(win or not), _amountIDOtoken, _amountUSDC, _idToken, _amountWinTickets, _amountLoseTickets, 

        if (_amountIDOtoken > 0) {
            _deliverTokens(_user, _amountIDOtoken);
        }

        if (_amountUSDC > 0) { 
            IERC20(USDC).transfer(_user, _amountUSDC);
        }
    
        burnTicketBatch(address(this), _idTicket, _totalTicket);

        _updatePurchasingState(_amountIDOtoken);

        for (uint256 i = 0; i < _idTicket.length; i++) {
            userTicket[_idTicket[i]][msg.sender] -= _totalTicket[i];
        }
        
        emit SwapToTokenBatch(_user, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket);
    }

    // function burnTicket(address _from, uint256 _id, uint256 _quantity) internal {
    //     ITicket(ticket).burn(_from, _id, _quantity);
    // }

    function burnTicketBatch(address _from, uint256[] memory _id, uint256[] memory _quantity) internal {
        ITicket(ticket).burnBatch(_from, _id, _quantity);
    }

    /**
     * @notice Return true if pool has ended
     * @dev User cannot purchase / trade tokens when isFinalized == true
     * @return true if the ICO Ended.
     */
    function isFinalized() public view returns (bool) {
        return block.timestamp >= closeTime;
    }

    /**
     * @notice Owner can receive their remaining tokens when ICO Ended
     * @dev  Can refund remainning token if the ico ended
     * @param _wallet Address wallet who receive the remainning tokens when Ico end
     * @param _amount Value of amount will exchange of tokens
     */
    function refundRemainingTokens(address _wallet, uint256 _amount)
        external
        onlyOwner
    {
        require(isFinalized(), "POOL::ICO_NOT_ENDED");
        require(IERC20(token).balanceOf(address(this)) > 0, "POOL::EMPTY_BALANCE");
        _deliverTokens(_wallet, _amount);
        emit RefundedIcoToken(_wallet, _amount);
    }


    /**
     * @dev Source of tokens. Transfer / mint
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        IERC20(token).transfer(_beneficiary, _tokenAmount);
        userPurchased[_beneficiary] = userPurchased[_beneficiary] + _tokenAmount;
    }


    /**
     * @dev Determines how Token is stored/forwarded on purchases.
     */
    function _forwardTokenFunds(uint256 _amount) internal {
        IERC20(USDC).transferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @param _tokens Value of sold tokens
     */
    function _updatePurchasingState(uint256 _tokens)
        internal
    {
        tokenSold = tokenSold + _tokens;
    }

    // @return true if the transaction can buy tokens
    function _validPurchase() internal view returns (bool) {
        bool withinPeriod =
            block.timestamp >= openTime && block.timestamp <= closeTime;
        return withinPeriod;
    }

    function _verifyAllowance(
        address _user,
        uint256 _amount
    ) private view {
        IERC20 tradeToken = IERC20(USDC);
        uint256 allowance = tradeToken.allowance(_user, address(this));
        require(allowance >= _amount, "POOL::TOKEN_NOT_APPROVED");
    }

    
    // /**
    //  * @dev Verify permission of minting ticket
    //  * @param proof merkle tree proof
    //  * @param _id nft id ticket
    //  * @param _candidate Address of buyer
    //  * @param _quantity amount ticket want to mint
    //  * @param _amount total CODE stake
    //  */
    // function _verifyMintTicket(
    //     address _candidate,
    //     uint256 _amount,
    //     uint256 _id,
    //     uint256 _quantity,
    //     bytes32[] memory proof
    // ) private view returns (bool) {
    //     if (useWhitelist) {
    //         return (verifyMintTicket(_candidate, _amount, _id, _quantity, proof));
    //     }
    //     return true;
    // }

    /**
     * @dev Verify permission of minting ticket
     * @param proof merkle tree proof
     * @param _id nft id ticket
     * @param _candidate Address of buyer
     * @param _quantity amount ticket want to mint
     * @param _amount total CODE stake
     */
    function _verifyMintTicketBatch(
        address _candidate,
        uint256 _amount,
        uint256[] memory _id,
        uint256[] memory _quantity,
        bytes32[] memory proof
    ) private view returns (bool) {
        if (useWhitelist) {
            return (verifyMintTicketBatch(_candidate, _amount, _id, _quantity, proof));
        }
        return true;
    }


    // /**
    //  * @dev Verify permission of minting ticket
    //  * @param proof merkle tree proof
    //  * @param _idTicket nft id ticket
    //  * @param _candidate Address of buyer
    //  * @param _totalTicket amount Ticket
    //  * @param _amountIDOtoken total IDO token will receive
    //  * @param _amountUSDC total USDC token will receive
    //  */
    // function _verifyResult(
    //     address _candidate,
    //     uint256 _amountIDOtoken,
    //     uint256 _amountUSDC,
    //     uint256 _idTicket,
    //     uint256 _totalTicket,
    //     bytes32[] memory proof
    // ) private view returns (bool) {
    //     if (useWhitelist) {
    //         return (verifyResult(_candidate, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket, proof));
    //     }
    //     return true;
    // }

   /**
     * @dev Verify permission of minting ticket
     * @param proof merkle tree proof
     * @param _idTicket all nft id ticket
     * @param _candidate Address of buyer
     * @param _totalTicket all amount Ticket of each id
     * @param _amountIDOtoken total IDO token will receive
     * @param _amountUSDC total USDC token will receive
     */
    function _verifyResultBatch(
        address _candidate,
        uint256 _amountIDOtoken,
        uint256 _amountUSDC,
        uint256[] memory _idTicket,
        uint256[] memory _totalTicket,
        bytes32[] memory proof
    ) private view returns (bool) {
        if (useWhitelist) {
            return (verifyResultBatch(_candidate, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket, proof));
        }
        return true;
    }

    //--------------------------------------------------------------
    //CHAINLINK
    //--------------------------------------------------------------

    // /**
    //  * Requests randomness
    //  */
    // function getRandomNumber() public returns (bytes32 requestId) {
    //     require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
    //     return requestRandomness(keyHash, fee);
    // }

    // /**
    //  * Callback function used by VRF Coordinator
    //  */
    // function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
    //     randomResult = randomness;
    // }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

interface IPoolFactory {
    function getTier() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ITicket is IERC1155 {

    function getCurrentID() external view returns(uint256);
    
    function getURI() external view returns (string memory);

    function getCreator(uint256 _id) external view returns (address);

    function setURI(uint256 _id, string memory _URI) external returns (bool);

    function mint(address _to, uint256 _id, uint256 _quantity, bytes memory _data) external;
    
    function mintBatch(address _to, uint256[] memory ids, uint256[] memory _quantity, bytes memory _data) external;

    function burn(address _from, uint256 _id, uint256 _quantity) external;

    function burnBatch(address _from, uint256[] memory _ids, uint256[] memory _quantity) external;

    function create(uint256 _maxSupply, uint256 _initialSupply, string memory _uri, bytes memory _data) external returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Signature Verification

contract KLAYDAOWhitelist {

    bytes32 public root;

    // function verifyMintTicket(
    //     address _candidate,
    //     uint256 _amount,
    //     uint256 _id,
    //     uint256 _quantity,
    //     bytes32[] memory proof
    // ) internal view returns (bool) {
    //     bytes32 leaf = keccak256(abi.encodePacked(_candidate, _amount, _id, _quantity));

    //     return MerkleProof.verify(proof, root, leaf);
    // }

    function verifyMintTicketBatch(
        address _candidate,
        uint256 _amount,
        uint256[] memory _id,
        uint256[] memory _quantity,
        bytes32[] memory proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_candidate, _amount, _id, _quantity));

        return MerkleProof.verify(proof, root, leaf);
    }

    // function verifyResult(
    //     address _candidate,
    //     uint256 _amountIDOtoken,
    //     uint256 _amountUSDC,
    //     uint256 _idTicket,
    //     uint256 _totalTicket,
    //     bytes32[] memory proof
    // ) internal view returns (bool) {
    //     bytes32 leaf = keccak256(abi.encodePacked(_candidate, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket));

    //     return MerkleProof.verify(proof, root, leaf);
    // }

    function verifyResultBatch(
        address _candidate,
        uint256 _amountIDOtoken,
        uint256 _amountUSDC,
        uint256[] memory _idTicket,
        uint256[] memory _totalTicket,
        bytes32[] memory proof
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_candidate, _amountIDOtoken, _amountUSDC, _idTicket, _totalTicket));

        return MerkleProof.verify(proof, root, leaf);
    }

    // function verifyBuyTicket(
    //     bytes32[] memory proof,
    //     address _candidate,
    //     uint256 _id,
    //     uint256 _quantity,
    //     uint256 _totalStaked
    // ) public view returns (bool) {
    //     bytes32 leaf = keccak256(abi.encodePacked(_candidate, _id, _quantity, _totalStaked));

    //     return MerkleProof.verify(proof, root, leaf);
    // }



    // // Using Openzeppelin ECDSA cryptography library
    // function getMessageHash(
    //     address _candidate,
    //     uint256 _maxAmount,
    //     uint256 _minAmount
    // ) public pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(_candidate, _maxAmount, _minAmount));
    // }

    // function getClaimMessageHash(
    //     address _candidate,
    //     uint256 _amount
    // ) public pure returns (bytes32) {
    //     return keccak256(abi.encodePacked(_candidate, _amount));
    // }

    // // Verify signature function
    // function verify(
    //     address _signer,
    //     address _candidate,
    //     uint256 _maxAmount,
    //     uint256 _minAmount,
    //     bytes memory signature
    // ) public pure returns (bool) {
    //     bytes32 messageHash = getMessageHash(_candidate, _maxAmount, _minAmount);
    //     bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

    //     return getSignerAddress(ethSignedMessageHash, signature) == _signer;
    // }

    // // Verify signature function
    // function verifyClaimToken(
    //     address _signer,
    //     address _candidate,
    //     uint256 _amount,
    //     bytes memory signature
    // ) public pure returns (bool) {
    //     bytes32 messageHash = getClaimMessageHash(_candidate, _amount);
    //     bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

    //     return getSignerAddress(ethSignedMessageHash, signature) == _signer;
    // }

    // function getSignerAddress(bytes32 _messageHash, bytes memory _signature) public pure returns(address signer) {
    //     return ECDSA.recover(_messageHash, _signature);
    // }

    // // Split signature to r, s, v
    // function splitSignature(bytes memory _signature)
    //     public
    //     pure
    //     returns (
    //         bytes32 r,
    //         bytes32 s,
    //         uint8 v
    //     )
    // {
    //     require(_signature.length == 65, "invalid signature length");

    //     assembly {
    //         r := mload(add(_signature, 32))
    //         s := mload(add(_signature, 64))
    //         v := byte(0, mload(add(_signature, 96)))
    //     }
    // }

    // function getEthSignedMessageHash(bytes32 _messageHash)
    //     public
    //     pure
    //     returns (bytes32)
    // {
    //     return ECDSA.toEthSignedMessageHash(_messageHash);
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
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