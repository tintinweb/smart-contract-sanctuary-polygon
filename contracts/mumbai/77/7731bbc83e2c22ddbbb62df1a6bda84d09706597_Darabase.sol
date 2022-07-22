// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./NFTContract.sol";
import "./LibOrder.sol";

/// @title Darabase contract
/// @notice For buying rentals in sale, distributing revenue and renewing rentals
contract Darabase is NFTContract{
    using ECDSA for bytes32;
    event FiatPayment(uint256 amount, string currency);

    uint256 public royaltyFee;
    uint256 public platformRenewPDRFee;
    uint256 public platformRevenueFee;
    address public platformFeeReceiver;
    uint256 public buyerFee;
    uint256 public sellerFee;
    bytes32 private DOMAIN_SEPARATOR;
    mapping(bytes32 => bool) public isComplete;

    function Darabase_init(
        uint256 _platformRenewPDRFee,
        uint256 _platformRevenueFee,
        uint256 _royaltyFee,
        address _platformFeeReceiver,
        address _admin,
        uint256 _buyerFee,
        uint256 _sellerFee,
        address owner
    ) external initializer {
        Nftcontract_init(_admin);
        Ownable_init(owner);
        royaltyFee = _royaltyFee;
        platformRenewPDRFee = _platformRenewPDRFee;
        platformRevenueFee = _platformRevenueFee;

        platformFeeReceiver = _platformFeeReceiver;
        
        buyerFee = _buyerFee;
        sellerFee = _sellerFee;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Darabase")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /// @notice buy Rental Primary Sale 
    /// @param sellOrder In Order struct, sell order 
    /// @param sellSignature In bytes, signature to be verified
    /// @param numberOfRentals In uint256, The number of rentals
    /// @param startTime In unix, start Time for rental
    /// @param endTime In unix, end Time for rental
    /// @param currency In string, currency 
    function buyRental(
        LibOrder.Order memory sellOrder,
        bytes memory sellSignature,
        uint256 numberOfRentals, 
        uint128 startTime,
        uint128 endTime,
        string memory currency
    ) external payable whenNotPaused{

        // Checking Prerequisites
        LibOrder.checkTime(startTime, endTime); 

        // To prevent Double Spending Attack
        checkAndCompleteOrder(LibOrder.orderHash(sellOrder));     

        // Validate Signatures
        validateOrderSignature(sellOrder, sellSignature);

        // Calculate Payment
        (uint256 totalPayment, uint256 buyPayment, uint256 platformPayment) = calculateTotalPayment(sellOrder.payment.amount, numberOfRentals, sellOrder.numberOfTokens);

        // Check Matic Balance
        checkMaticBalance(sellOrder.payment.paymentClass, totalPayment);

        // Platform Fee
        doPlatformPayment(msg.sender, sellOrder.payment, platformPayment, currency);

        if(sellOrder.orderType == LibOrder.PRIMARY_TYPE){
            // Trade
            doPaymentTransfer(msg.sender, sellOrder.pdrId, totalPayment, buyPayment, platformPayment, sellOrder.maker, sellOrder.payment, false, currency);
            
            // Check if the order maker is the pdr Owner
            if(sellOrder.maker != getPdrOwner(sellOrder.pdrId)) revert("Seller is not the pdr owner");
            
            // Create and Transfer Rental NFT
            transferRentalPrimary(sellOrder.maker, msg.sender, sellOrder.pdrId, sellOrder.nftId, numberOfRentals, startTime, endTime);
        }
        else if(sellOrder.orderType == LibOrder.SECONDARY_TYPE){
            // Trade
            doPaymentTransfer(msg.sender, sellOrder.pdrId, totalPayment, buyPayment, platformPayment, sellOrder.maker, sellOrder.payment, true, currency);

            // Check if the order maker is the rental Owner
            if(sellOrder.maker != getRentalOwner(sellOrder.rentalId)) revert("Seller is not the rental owner");
            // Create and Transfer Rental NFT
            transferRentalSecondary(sellOrder.maker, msg.sender, sellOrder.rentalId, sellOrder.nftId, sellOrder.pdrId, numberOfRentals, startTime, endTime);
        }
        else{
            revert("Invalid buy rental type");
        }

    }

    function checkMaticBalance(bytes4 paymentClass, uint totalPayment) internal view{
        if(paymentClass == LibOrder.MATIC_PAYMENT_CLASS) {
            if(msg.value < totalPayment) revert("Insufficient payment");
        }
    }

    /// @notice renew Rental
    /// @param renewOrder In Order struct, sell order 
    /// @param renewSignature In bytes, signature to be verified
    /// @param startTime In unix, start Time for rental
    /// @param endTime In unix, end Time for rental
    /// @param currency In string, currency
    function renewRental(
        LibOrder.Order memory renewOrder,
        bytes memory renewSignature,
        uint128 startTime,
        uint128 endTime,
        string memory currency
    ) external payable whenNotPaused{

        // Checking Prerequisites
        require(renewOrder.orderType == LibOrder.RENEW_TYPE, "Not a renew order");
        require(msg.sender == getRentalOwner(renewOrder.rentalId),"Only rental owner");
        LibOrder.checkTime(startTime, endTime); 

        // To prevent Double Spending Attack
        checkAndCompleteOrder(LibOrder.orderHash(renewOrder));

        // Validate Signatures
        validateOrderSignature(renewOrder, renewSignature);

        // Check if the order maker is pdr Owner
        if(renewOrder.maker != getPdrOwner(renewOrder.pdrId)) revert("Renew order maker is not the pdr owner");

        // Calculate Payment
        (uint256 totalPayment, uint256 buyPayment, uint256 platformPayment) = calculateTotalPayment(renewOrder.payment.amount, balanceOf(getRentalDetails(renewOrder.rentalId).renter, renewOrder.rentalId), renewOrder.numberOfTokens);
        
        // Check Matic Balance
        checkMaticBalance(renewOrder.payment.paymentClass, totalPayment);

        // Platform Fee
        doPlatformPayment(msg.sender, renewOrder.payment, platformPayment, currency);

        // Trade
        doPaymentTransfer(msg.sender, renewOrder.pdrId, totalPayment, buyPayment, platformPayment, renewOrder.maker, renewOrder.payment, true, currency);
        
        // Update Rental NFT
        updateRental(renewOrder.rentalId, startTime, endTime);
    }

    function calculateTotalPaymentForRevenueDist(
        uint256 amount,
        uint256 numberOfTokens
    ) internal pure returns(uint256 totalPayment){
        totalPayment = amount * numberOfTokens;
    }

    function checkAndCompleteOrder(bytes32 _orderHash) public {
        require(!isComplete[_orderHash], "Order already complete");
        isComplete[_orderHash] = true;
    }

    /// @notice distribute revenue
    /// @param pdrId In uint256, pdr Id
    /// @param amountPerNFT In uint256, amount per Nft
    /// @param accounts In address[], addresses of all accounts to whom revenue is to be distributed
    /// @param payment In payment struct
    /// @param currency In string, currency
    function distributeRevenue(
        uint256 pdrId, 
        uint256 amountPerNFT, 
        address[] calldata accounts, 
        LibOrder.Payment memory payment,
        string memory currency
    ) public payable whenNotPaused{

        // Check Prerequisites
        require(getTokenType(pdrId) == TokenType.PDR, "Incorrect pdr");
        address ownerPdr = getPdrOwner(pdrId);
        require(msg.sender == ownerPdr || msg.sender == owner() || msg.sender == admin, "Only owner/ownerNft/admin");

        // Calculate Payment
        uint256 numberOfTokens = pdrLimit[pdrId];

        (uint256 totalPayment) = calculateTotalPaymentForRevenueDist(amountPerNFT, numberOfTokens);

        // Distribute Revenue
        (bool sendRemainingtoPDROwner, uint completedRevenuePayment, uint platformPayment) = distribute(pdrId, ownerPdr, accounts, numberOfTokens, totalPayment, platformRevenueFee, payment, currency);

        //Platform payment
        doPlatformPayment(msg.sender, payment, platformPayment, currency);

        // Send Remaining to PDR Owner if applicable
        uint256 remainingBalance;
        if(sendRemainingtoPDROwner){
            doRevenueTransfer(msg.sender, totalPayment - platformPayment - completedRevenuePayment , ownerPdr, payment, currency);
            if(payment.paymentClass == LibOrder.MATIC_PAYMENT_CLASS ){
                // refund remaining matic if payment class is MATIC
                 remainingBalance = msg.value - totalPayment;
            }
        } else{
            if(payment.paymentClass == LibOrder.MATIC_PAYMENT_CLASS ){
                // refund remaining matic if payment class is MATIC
                remainingBalance = msg.value - platformPayment - completedRevenuePayment;
            }
        }
        
        // Refund extra MATIC back to caller
        if(remainingBalance > 0) Address.sendValue(payable(msg.sender), remainingBalance);
        
    }

    function distribute(
        uint pdrId,
        address ownerPdr,
        address[] calldata accounts,
        uint numberOfTokens,
        uint netPayment,
        uint256 platformFee,
        LibOrder.Payment memory payment,
        string memory currency
     ) internal returns(bool sendRemainingToRwoOwner, uint completedRevenuePayment, uint platformPayment){
        address renter;
        uint256[] memory rentals = pdrToRental[pdrId];
        uint256 fee;
        for(uint256 i=0; i<accounts.length; i++){
            if(accounts[i] == ownerPdr) 
            {   sendRemainingToRwoOwner = true;
                break;
            }
        }

        for(uint256 i=0; i<rentals.length; i++){
            renter = getRentalOwner(rentals[i]);
            if(LibOrder.searchIfRentalOwnerMatches(accounts, renter)){
                fee = (netPayment * balanceOf(renter, rentals[i]) ) / numberOfTokens;
                fee = fee - ((fee * platformFee) / 10000);
                completedRevenuePayment += fee;
                doRevenueTransfer(msg.sender, fee, renter, payment, currency);
            }
        }

        platformPayment = (completedRevenuePayment * platformFee)/(10000-(platformFee));              
    }
    

    /// @notice Calculate total payment
    /// @param amount In uint256, the amount 
    /// @param numberOfRentals In uint256, number of rentals 
    /// @param totalNumberOfRentals  In uint256, number of tokens
    function calculateTotalPayment(
        uint256 amount,
        uint256 numberOfRentals,
        uint256 totalNumberOfRentals
    ) internal view returns(uint256 totalPayment, uint256 buyPayment, uint256 platformPayment){
        require(numberOfRentals <= totalNumberOfRentals, "Requested number of rentals greater than the order");
        amount = (amount * numberOfRentals) / totalNumberOfRentals;
        totalPayment = amount + ((amount * buyerFee) / 10000);
        buyPayment = amount;
        platformPayment = ((amount * (buyerFee + sellerFee)) / 10000);
    }



    /// @notice Validate signature
    /// @param orderHash bytes32 hash of struct Order
    /// @param sellSignature In bytes32, order signature to be verified with
    /// @param maker Address of signature owner
    function validateSignature(
        bytes32 orderHash, 
        bytes memory sellSignature, 
        address maker
    ) internal view{
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                orderHash
            )
        );

        address signer = digest.recover(sellSignature);
        if(signer == address(0) || signer != maker) revert InvalidSignature();
    }

    /// @notice Validate order signature
    /// @param order In order struct, order
    /// @param orderSignature In bytes32, order signature to be verified with
    function validateOrderSignature(
        LibOrder.Order memory order, 
        bytes memory orderSignature
    ) internal view{

        if (order.salt == 0) revert("Invalid salt");

        bytes32 digest = keccak256(abi.encode(
                    LibOrder.ORDER_TYPEHASH,
                    order.maker, 
                    order.rentalId,
                    order.pdrId, 
                    order.nftId,
                    order.numberOfTokens,
                    order.salt,
                    order.orderType,
                    LibOrder.paymentHash(order.payment)
                    ));
        validateSignature(digest, orderSignature, order.maker);  
    }

    /// @notice Platform payment in erc20/matic
    /// @param from Address of account making the transfer
    /// @param payment Payment struct
    /// @param platformPayment In uint256, platform payment to be made
    function doPlatformPayment(
        address from, 
        LibOrder.Payment memory payment, 
        uint256 platformPayment,
        string memory currency
    ) internal {
        // Transfer platform fees
        if (payment.paymentClass == LibOrder.MATIC_PAYMENT_CLASS) {

            // Pay platform fee
            LibOrder.transferMatic(platformFeeReceiver, platformPayment);
        } else if( payment.paymentClass == LibOrder.ERC20_PAYMENT_CLASS){
            (address token) = abi.decode(payment.data, (address));
            
            // Pay platform fee
            LibOrder.doERC20Transfer(token,from, platformFeeReceiver, platformPayment);
        } else if( payment.paymentClass == LibOrder.FIAT_PAYMENT_CLASS){
            emit FiatPayment(platformPayment, currency);
        } else{
            revert("Invalid payment class");
        }
    }

    /// @notice Transfer royalty and payment 
    /// @param from Address of account from which payment is to be made
    /// @param totalPayment In uint256, total payment 
    /// @param seller Address of seller to whom remaining payment is sent
    /// @param payment In payment struct
    /// @param isRoyalty If royalty is to be paid
    /// @param currency In string, currency
    function doPaymentTransfer(
        address from,
        uint pdrId,
        uint256 totalPayment, 
        uint256 buyPayment,
        uint256 platformPayment,
        address seller, 
        LibOrder.Payment memory payment,
        bool isRoyalty,
        string memory currency
    ) internal {
        // Transfer platform fees
        uint256 remainingPayment = totalPayment - platformPayment;
        uint256 royaltyPayment;
        uint256 _royaltyFee = royaltyFee;

        if (payment.paymentClass == LibOrder.MATIC_PAYMENT_CLASS) {
            if(isRoyalty && (_royaltyFee > 0)){
                // Transfer royalties
                royaltyPayment = (buyPayment*_royaltyFee) / 10000;
                LibOrder.transferMatic(getPdrOwner(pdrId), royaltyPayment);
                remainingPayment -= royaltyPayment;       
            }
            // Transfer remaining payment to seller
            LibOrder.transferMatic(seller, remainingPayment);
        } else if( payment.paymentClass == LibOrder.ERC20_PAYMENT_CLASS){
            (address token) = abi.decode(payment.data, (address));
            if(isRoyalty && (_royaltyFee > 0)){
                // Transfer royalties
                royaltyPayment = (buyPayment*_royaltyFee) / 10000;

                LibOrder.doERC20Transfer(token, from, getPdrOwner(pdrId), royaltyPayment);
                remainingPayment -= royaltyPayment;
            }
            // Transfer remaining payment to seller
            LibOrder.doERC20Transfer(token, from, seller, remainingPayment);
        } else if( payment.paymentClass == LibOrder.FIAT_PAYMENT_CLASS){
            emit FiatPayment(totalPayment, currency);
        } else{
            revert("Invalid payment class");
        }
    }

    /// @notice Transfer royalty and payment 
    /// @param from Address of account from which payment is to be made
    /// @param netPayment In uint256, net Payment 
    /// @param receiver Address of receiver to whom remaining payment is sent
    /// @param payment In payment struct
    /// @param currency In string, currency
    function doRevenueTransfer(
        address from,
        uint256 netPayment,
        address receiver,
        LibOrder.Payment memory payment,
        string memory currency
    ) internal {

        if (payment.paymentClass == LibOrder.MATIC_PAYMENT_CLASS) {

            // Transfer remaining payment to receiver
            LibOrder.transferMatic(receiver, netPayment);
        } else if( payment.paymentClass == LibOrder.ERC20_PAYMENT_CLASS){
            (address token) = abi.decode(payment.data, (address));

            // Transfer remaining payment to seller
            LibOrder.doERC20Transfer(token, from, receiver, netPayment);
        } else if( payment.paymentClass == LibOrder.FIAT_PAYMENT_CLASS){
            emit FiatPayment(netPayment, currency);
        } else{
            revert("Invalid payment class");
        }
    }

    /// @notice set platform renew fee
    /// @param _platformRenewPDRFee In uint256, new platform renew fee
    function setPlatformRenewPDRFee(
        uint256 _platformRenewPDRFee
    ) external onlyAdminOrOwner whenNotPaused{
        platformRenewPDRFee = _platformRenewPDRFee;
    }

    /// @notice set platform fee
    /// @param _platformRevenueFee In uint256, new platform revenue fee
    function setPlatformRevenueFee(
        uint256 _platformRevenueFee
    ) external onlyAdminOrOwner whenNotPaused{
        platformRevenueFee = _platformRevenueFee;
    }

    /// @notice set royalty fee
    /// @param _newRoyaltyFee In uint256, new royalty fee
    function setRoyaltyFee(
        uint256 _newRoyaltyFee
    ) external onlyAdminOrOwner whenNotPaused{
        royaltyFee = _newRoyaltyFee;
    }

    /// @notice set platform fee receiver
    /// @param _newPlatformFeeReceiver Address of new platform fee receiver
    function setPlatformFeeReceiver(
        address _newPlatformFeeReceiver
    ) external onlyAdminOrOwner whenNotPaused{
        platformFeeReceiver = _newPlatformFeeReceiver;
    }

    /// @notice set buyer and seller fee
    /// @param _newBuyerFee In uint256, new buyer fee
    /// @param _newSellerFee In uint256, new Seller fee
    function setBuyerAndSellerFee(
        uint256 _newBuyerFee,
        uint256 _newSellerFee
    ) external onlyAdminOrOwner whenNotPaused{
        buyerFee = _newBuyerFee;
        sellerFee = _newSellerFee;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./Pausable.sol";
import "./Strings.sol";

/// @title NFT contract
/// @notice This contract manages rwo, pdr and rental nfts
contract NFTContract is ERC1155, Ownable, Pausable{
    using Strings for uint256;

    event AdminUpdated( address admin, address newAdmin);

    struct Rental{
        address renter;
        uint128 startTime;
        uint128 endTime;
    }

    address public admin;
    string public baseURI;

    enum TokenType{RWO, PDR, RENTAL}

    // rwoId => owner
    mapping(uint256 => address) private rwoOwner;

    // pdrId => owner
    mapping(uint256 => address) private pdrOwner;

    // pdrId => pdr amount limit
    mapping(uint256 => uint256) public pdrLimit;

    // rentalId -> Rental
    mapping(uint256 => Rental) private rental;

    // Total rental amount
    mapping(uint256 => uint256) private rentalAmount;

    // rwo and pdr mapping to token type
    mapping(uint256 => TokenType) internal tokenType;

    // rwo id => pdr ids []
    mapping (uint256 => uint256[]) private rwoToPdr;

    // pdr id => rental ids
    mapping(uint256 => uint256[]) public pdrToRental;

    // rental id => pdr id
    mapping(uint256 => uint256) public rentalIdToPDRId;

    mapping(uint256 => bool) private isPDRBurned;

    // pdr id to rwo id
    mapping(uint256 => uint256) private pdrToRwo;

    // is NFT id created
    mapping(uint256 => bool) private isCreated;
     
    modifier onlyAdminOrOwner {
        require(owner() == msg.sender || admin == msg.sender, "Only admin/owner");
        _;
    }

    function Nftcontract_init(address _admin) internal initializer{
        admin = _admin;
        // Blocking id = 0, for default nft id usage
        checkAndStoreDuplicateNFTID(0);
    }

    function checkAndStoreDuplicateNFTID(uint256 nftId) internal{
        if(isCreated[nftId]) revert("Nft id already created");
        isCreated[nftId] = true;
    }


    /// @notice Mints Rwo by onlyAdminOrOwner
    /// @param to Address to which rwo will be minted
    function mintRWO(
        address to,
        uint256 nftId
    ) external onlyAdminOrOwner whenNotPaused{

        // Create NFT Data
        tokenType[nftId] = TokenType.RWO;
        checkAndStoreDuplicateNFTID(nftId);

        // Mint
        _mint(to, nftId, 1, "");

        // Set Owner
        rwoOwner[nftId] = to;
    }

    /// @notice Mints Pdr by onlyAdminOrOwner
    /// @param rwoId in uint256, rwo id to be linked to pdr
    /// @param amount in uint256, amount of pdr minted
    function mintPDR(
        uint256 rwoId, 
        uint256 nftId,
        uint256 amount
    ) external onlyAdminOrOwner whenNotPaused{

        // Prerequisites
        if(getTokenType(rwoId) != TokenType.RWO) revert("Incorrect Rwo id");

        // Check for duplicate NFT ID
        checkAndStoreDuplicateNFTID(nftId);
        pdrLimit[nftId] = amount;

        // NFT Data
        tokenType[nftId] = TokenType.PDR;
        address ownerRwo = getRwoOwner(rwoId);
        pdrOwner[nftId] = ownerRwo;
        rwoToPdr[rwoId].push(nftId);
        pdrToRwo[nftId] = rwoId;

        // Mint
        _mint(ownerRwo, nftId, amount, "");
    }

    /// @notice  Mints Rental Ids
    /// @param pdrId already minted pdr id to be linked to rental
    /// @param to Address to which renter will be minted
    /// @param amount in uint256, amount of rentals minted
    /// @param startTime in unix, time from which rental will be minted
    /// @param endTime in unix, time till which rental will be minted
    function mintRentalToken(
        uint256 pdrId, 
        uint256 nftId,
        address to, 
        uint256 amount,
        uint128 startTime, 
        uint128 endTime
    ) internal{

        // Prerequisites
        require(getTokenType(pdrId) == TokenType.PDR, "Invalid PDR id");

        // Check for duplicate NFT ID
        checkAndStoreDuplicateNFTID(nftId);
        
        // NFT Data
        uint256 rentalId = nftId;
        tokenType[rentalId] = TokenType.RENTAL;
        rentalAmount[rentalId] = amount;
        rental[rentalId] = Rental(to, startTime, endTime);
        rentalIdToPDRId[rentalId] = pdrId;

        // forward mapping
        pdrToRental[pdrId].push(rentalId);

        // Mint
        _mint(to, rentalId, amount, "");

    }

    /// @notice Transfers rental in primary sale
    /// @param to Address to which renter will be transferred
    /// @param pdrId already minted pdr id to be linked to transferred
    /// @param amount in uint256, amount of rentals transferred
    /// @param startTime in unix, time from which rental will be transferred
    /// @param endTime in unix, time till which rental will be transferred
    function transferRentalPrimary(
        address from,
        address to,
        uint256 pdrId,
        uint256 nftId,
        uint256 amount,
        uint128 startTime,
        uint128 endTime
    ) internal{

        // Prerequisites
        require(getTokenType(pdrId) == TokenType.PDR, "Invalid PDR id");

        // Check Balance
        if(balanceOf(from, pdrId) < amount) revert("Insufficient PDR balance");

        // Deduct Balance
        _balances[pdrId][from] -= amount;

        // Mint Rental
        mintRentalToken(pdrId, nftId, to, amount, startTime, endTime);
    }

    /// @notice Transfers rental in secondary sale
    /// @param to Address to which renter will be transferred
    /// @param pdrId already minted pdr id to be linked to transferred
    /// @param amount in uint256, amount of rentals transferred
    /// @param startTime in unix, time from which rental will be transferred
    /// @param endTime in unix, time till which rental will be transferred
    function transferRentalSecondary(
        address from,
        address to,
        uint256 rentalId,
        uint256 nftId,
        uint256 pdrId,
        uint256 amount,
        uint128 startTime,
        uint128 endTime
    ) internal{

        // Prerequisites
        require(getTokenType(rentalId) == TokenType.RENTAL, "Invalid rental id");

        // Balance check
        require(amount <= balanceOf(from, rentalId), "Insufficient balance");

        // Deduct amount of rentalId from from address
        _balances[rentalId][from] -= amount;
        rentalAmount[rentalId] -= amount;

        // Mint Rental
        mintRentalToken(pdrId, nftId, to, amount, startTime, endTime);
    }

    /// @notice Transfer Rwo id by admin/owner/RWOOwner
    /// @param to Address to which Rwo id is to be transferred
    /// @param rwoId In uint256, Rwo id which is to be transferred
    function transferRWO(
        address to,
        uint256 rwoId
    ) external whenNotPaused{

        // Prerequisites
        require(getTokenType(rwoId) == TokenType.RWO, "Not a RWO");
        address _rwoOwner = getRwoOwner(rwoId);
        require(msg.sender == admin || msg.sender == owner() || msg.sender == _rwoOwner, "Only admin/owner/RWOOwner");

        uint256 pdrId;
        uint256 pdrAmount;
        address _pdrOwner;
        
        // Transfer PDR Along with RWO
        for(uint256 i=0; i< getPdrFromRwo(rwoId).length; i++){
            pdrId = rwoToPdr[rwoId][i];

            // Check if pdr is burned
            if(isPDRBurned[pdrId]) continue;

            _pdrOwner = getPdrOwner(pdrId);

            // Dont transfer pdr if rwo owner is not the pdr owner
            if(_pdrOwner != _rwoOwner) continue;
            pdrAmount = balanceOf(_pdrOwner, pdrId);
            safeTransferFrom(_rwoOwner, to, pdrId, pdrAmount, "");

            // Update pdr owner mapping
            setPdrOwner(pdrId, to);
        }
        
        // Update RWO Owner
        setRwoOwner(rwoId, to);
        safeTransferFrom(_rwoOwner, to, rwoId, balanceOf(_rwoOwner, rwoId), "");
    }

    /// @notice Transfer PDR id by admin/owner/RWOOwner
    /// @param to Address to which Pdr id is to be transferred
    /// @param pdrId In uint256, Pdr id which is to be transferred
    function transferPDR(
        address to,
        uint256 pdrId
    ) external whenNotPaused{

        // Prerequisites
        require(getTokenType(pdrId) == TokenType.PDR, "Not a PDR");
        address _pdrOwner = getPdrOwner(pdrId);
        require(msg.sender == admin || msg.sender == owner() || msg.sender == _pdrOwner, "Only admin/owner/PDR Owner");
        
        // Check if pdr is burned
        if(isPDRBurned[pdrId]) revert("Pdr is burned");

        // Update PDR Owner
        setPdrOwner(pdrId, to);

        safeTransferFrom(_pdrOwner, to, pdrId, balanceOf(_pdrOwner, pdrId), "");
    }

    /// @notice Calculate tree age in years, rounded up, for live trees
    /// @param rentalId In uint256, Rental id of which start and end time have to be updated
    /// @param startTime In unix, new start time
    /// @param endTime In unix, new end time
    function updateRental(
        uint256 rentalId,
        uint128 startTime,
        uint128 endTime
    ) internal{
        rental[rentalId].startTime = startTime;
        rental[rentalId].endTime = endTime;
    }

    /// @notice Get token type
    /// @param tokenId In uint256, token id
    /// @return TokenType either rwo or pdr as type of token id
    function getTokenType(
        uint256 tokenId
    ) public view returns(TokenType) {
        if(!isCreated[tokenId] || tokenId == 0) revert("Id doesnt exist");
        return tokenType[tokenId];
    }

    /// @notice Get rwo id owner
    /// @param rwoId In uint256, rwo id
    /// @return rwoOwner Address of rwo id owner
    function getRwoOwner(
        uint256 rwoId
    ) public view returns(address){
        return rwoOwner[rwoId];
    }

    function setRwoOwner(uint256 rwoId, address newOwner) internal {
        rwoOwner[rwoId] = newOwner;
    }

    /// @notice Get pdr id owner
    /// @param pdrId In uint256, pdr id
    /// @return pdrOwner Address of pdr id owner
    function getPdrOwner(
        uint256 pdrId
    ) public view returns(address){
        return pdrOwner[pdrId];
    }

    function setPdrOwner(uint256 pdrId, address newOwner) internal {
        pdrOwner[pdrId] = newOwner;
    }

    /// @notice Get rental id owner
    /// @param rentalId In uint256, rental id
    /// @return rentalOwner Address of rental id owner
    function getRentalOwner(
        uint256 rentalId
    ) public view returns(address){
        return rental[rentalId].renter;
    }

    /// @notice Get rental details
    /// @param rentalId In uint256, rental id
    /// @return rentalDetails In rental, returns details like rentalId, renter, amount, startTime, endTime
    function getRentalDetails(
        uint256 rentalId
    ) public view returns(Rental memory){
        return rental[rentalId];
    }

    /// @notice Get Pdr id from Rwo id
    /// @param rwoId In uint256, rwo id
    /// @return pdrIds In uint256[], all Pdr ids associated to rwo id 
    function getPdrFromRwo(
        uint256 rwoId
    ) public view returns(uint256[] memory) {
        return rwoToPdr[rwoId];
    }

    /// @notice Get Rwo id from pdr id
    /// @param pdrId In uint256, pdr id
    /// @return rwoId In uint256, rwo id associated to pdr 
    function getRwoFromPdr(
        uint256 pdrId
    ) external view returns(uint256){
        return pdrToRwo[pdrId];
    }  

    /// @notice Sets new admin by owner
    /// @param newAdmin Address of new admin
    function setAdmin(
        address newAdmin
    ) external onlyOwner whenNotPaused{
        emit AdminUpdated( admin, newAdmin);
        admin = newAdmin;
    }

    /// @notice Pauses the contract by only owner
    function pause() external whenNotPaused onlyOwner{
        _pause();
    }

    /// @notice Unpauses the contract by only owner
    function unpause() external whenPaused onlyOwner{
        _unpause();
    }

    /// @notice Checks if the contract is paused
    function isContractPaused() public view virtual returns (bool) {
        return paused();
    }

    function setBaseURI(string memory _baseURI) external onlyAdminOrOwner whenNotPaused {
        baseURI = _baseURI;
    }

    function uri(uint256 id) public view returns (string memory){
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    function getRentalAmount(uint256 rentalId) public view returns(uint256){
        return rentalAmount[rentalId];
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public whenNotPaused {

        // Caller has to be either owner or admin, or rwo owner
        bool notOwnerOrAdmin;
        if(msg.sender != owner() && msg.sender != admin) notOwnerOrAdmin = true;

        if(getTokenType(id) == TokenType.RWO) {

            // Check caller
            if(getRwoOwner(id) != msg.sender && notOwnerOrAdmin) revert("Not owner, admin or rwo Owner");

            uint256[] memory pdrs = rwoToPdr[id];
            address _pdrOwner;

            // Burn related PDRs
            for(uint256 i =0; i < pdrs.length; i++){
                _pdrOwner = getPdrOwner(pdrs[i]);

                // Dont transfer pdr if rwo owner is not the pdr owner
                if(_pdrOwner != getRwoOwner(id)) continue;

                // Set all pdrs are burned
                isPDRBurned[pdrs[i]] = true;

                // Burn the pdr limit
                _burn(_pdrOwner, pdrs[i], pdrLimit[pdrs[i]], true);

                // Reset the pdr limit
                pdrLimit[pdrs[i]] = 0;
            }
            
            _burn(from, id, amount, false);
    
        } else if(getTokenType(id) == TokenType.PDR) {

            // Checks
            if(getPdrOwner(id) != msg.sender && notOwnerOrAdmin) revert("Not owner, admin or pdr Owner");
            if(amount != pdrLimit[id]) revert("Must burn all the pdrs");

            // Set all pdrs are burned
            isPDRBurned[id] = true;

            // Burn the pdr limit
            _burn(from, id, pdrLimit[id], true);

            // Reset the pdr limit
            pdrLimit[id] = 0;
        
        } else if(getTokenType(id) == TokenType.RENTAL) {
            address rentalOwner = getRentalOwner(id);

            // Checks
            if(rentalOwner != msg.sender && notOwnerOrAdmin) revert("Not owner, admin or rental Owner");
            if(balanceOf(rentalOwner, id) < amount) revert("Insufficient rentals to burn");

            // Deduct Rental NFT amount by amount
            rentalAmount[id] -= amount;
            
            // Return the balance to the pdr balance
            _balances[rentalIdToPDRId[id]][getPdrOwner(rentalIdToPDRId[id])] += amount;

            // Burn amount of rentals
            _burn(from, id, amount, false);

        } else {
            revert("Invalid token");
        }

    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");

        // If rental is expired or corresponding PDR burned => return 0
        if(getTokenType(id) == TokenType.RENTAL){
            if(rental[id].startTime > block.timestamp || rental[id].endTime < block.timestamp || isPdrBurned(rentalIdToPDRId[id])) return 0;
        }

        return _balances[id][account];
    }

    function isPdrBurned(uint256 pdrId) public view returns(bool){
        require(getTokenType(pdrId) == TokenType.PDR, "Not a pdr");
        return isPDRBurned[pdrId];
    }

    function returnRentalToPDRBalance(uint256 rentalId) external onlyAdminOrOwner whenNotPaused {
        uint256 _rentalAmount = getRentalAmount(rentalId);
        address rentalOwner = getRentalOwner(rentalId);

        // Check if there is sufficient rental amount and it is expired
        require(_rentalAmount > 0 && balanceOf(rentalOwner, rentalId) == 0, "Rental balance insufficient or not expired yet" );

        uint256 pdrId = rentalIdToPDRId[rentalId];

        /* Burn the rental NFTs */

        // Deduct Rental NFT amount by amount
        rentalAmount[rentalId] -= _rentalAmount;

        // Burn amount of rentals
        _burn(rentalOwner, rentalId, _rentalAmount, false);

        // Return the balance to pdr balance
        _balances[pdrId][getPdrOwner(pdrId)] += _rentalAmount;
    }

    function _beforeTokenTransfer(
        address,
        address,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        for(uint256 i=0; i< ids.length; i++){
            if(getTokenType(ids[i]) == TokenType.PDR) setPdrOwner(ids[i], to);
            if(getTokenType(ids[i]) == TokenType.RWO) setRwoOwner(ids[i], to);            
        }
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return operator == admin || operator == owner() || super.isApprovedForAll(account, operator);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./IERC20.sol";

error InvalidSignature();

/// @title Darabase contract
/// @notice For buying rentals in sale, distributing revenue and renewing rentals
library LibOrder{
    struct Payment{
        bytes4 paymentClass;
        uint256 amount;
        bytes data;
    }

    struct Order{
        address maker;
        uint256 rentalId; // will be 0 when not needed in primary sale, rental id can never be 0
        uint256 pdrId;
        uint256 nftId; // default value is 0
        uint256 numberOfTokens;
        uint256 salt;
        Payment payment;
        bytes4 orderType; // can be PRIMARY, SECONDARY, or RENEW
    }

    bytes4 constant public MATIC_PAYMENT_CLASS = bytes4(keccak256("MATIC")); // 0xa6a7de01
    bytes4 constant public ERC20_PAYMENT_CLASS = bytes4(keccak256("ERC20")); // 0x8ae85d84
    bytes4 constant public FIAT_PAYMENT_CLASS = bytes4(keccak256("FIAT")); // 0xd6d95ec8

    bytes4 constant public PRIMARY_TYPE = bytes4(keccak256("PRIMARY")); // 0x58c79ae7
    bytes4 constant public SECONDARY_TYPE = bytes4(keccak256("SECONDARY")); // 0x1192b932
    bytes4 constant public RENEW_TYPE = bytes4(keccak256("RENEW")); // 0xd64d87b2

    bytes32 constant PAYMENT_TYPEHASH = keccak256(
        "Payment(bytes4 paymentClass,uint256 amount,bytes data)"
    );

    bytes32 internal constant ORDER_TYPEHASH =
        keccak256("Order(address maker,uint256 rentalId,uint256 pdrId,uint256 nftId,uint256 numberOfTokens,uint256 salt,bytes4 orderType,Payment payment)Payment(bytes4 paymentClass,uint256 amount,bytes data)");
    
    /// @notice Generate payment Hash
    /// @param payment In payment struct, payment class, amount and data
    /// @return paymentHash In bytes32, hash of payment
    function paymentHash(
        Payment memory payment
    ) internal pure returns(bytes32){
        return keccak256(abi.encode(PAYMENT_TYPEHASH, payment.paymentClass, payment.amount, keccak256(payment.data)));
    }

    /// @notice Transfer in matic
    /// @param to Address of account to transfer matic to
    /// @param value In uint256, amount to be transferred
    function transferMatic(
        address to, 
        uint256 value
    ) internal{
        (bool success,) = to.call{ value: value }("");
        require(success, "matic transfer failed");
    }

    function checkTime(uint startTime, uint endTime) pure internal{
        require(startTime < endTime, "End time should be greater than start time");  
    }

    function hash(Payment memory payment) internal pure returns(bytes32){
        return keccak256(abi.encode(
                PAYMENT_TYPEHASH,
                payment.paymentClass,
                payment.amount,
                keccak256(payment.data)
            ));
    }

    function orderHash(LibOrder.Order memory order) internal pure returns(bytes32){
        return keccak256(abi.encode(
                order.maker,
                order.rentalId,
                order.pdrId,
                order.nftId,
                order.numberOfTokens,
                order.salt,
                hash(order.payment),
                order.orderType
            ));
    }

    function doERC20Transfer(address token, address from, address to, uint256 amount) internal{
        require(IERC20(token).transferFrom(from, to, amount), "failed while transferring erc20");
    }

    /// @notice Checks if rental owner exists in accounts array
    /// @param accounts In address[], all account addresses
    /// @param ownerRental Address of owner of rental
    /// @return boolVal Returns if rental owner exists in accounts array
    function searchIfRentalOwnerMatches(
        address[] calldata accounts, 
        address ownerRental
    ) internal pure returns(bool){
        for (uint256 i= 0; i< accounts.length; i++){
            if (accounts[i] == ownerRental){
                return true;
            }
        }
        return false;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;
import "./Context.sol";
import "./Initializable.sol";
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
abstract contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function Ownable_init(address newOwner) internal initializer {
        _owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./Address.sol";
import "./Context.sol";
import "./ERC165.sol";
/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155{
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount,
        bool skipBalanceCheckAndUpdate
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        if(!skipBalanceCheckAndUpdate){
            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        } else{
            _balances[id][from] = 0;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

    // function _msgData() internal view virtual returns (bytes calldata) {
    //     return msg.data;
    // }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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