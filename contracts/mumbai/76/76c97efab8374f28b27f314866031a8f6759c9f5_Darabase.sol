// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./IERC20.sol";
import "./NFTContract.sol";
import "./Signature.sol";

/// @title Darabase contract
/// @notice For buying rentals in sale, distributing revenue and renewing rentals
contract Darabase is NFTContract{
    using ECDSA for bytes32;
    event FiatPayment(uint256 amount, string currency);
    event SellerAndBuyerFeeSet(uint256 buyerFee, uint256 sellerFee);

    uint256 public royaltyFee;
    uint256 public platformPrimaryRentPDRFee;
    uint256 public platformSecondaryRentPDRFee;
    uint256 public platformRenewPDRFee;
    uint256 public platformRevenueFee;
    address public platformFeeReceiver;
    address public royaltiesReceiver;
    uint256 public buyerFee;
    uint256 public sellerFee;
    bytes32 private DOMAIN_SEPARATOR;

    function darabase_init( 
        uint256 _platformPrimaryRentPDRFee,
        uint256 _platformSecondaryRentPDRFee,
        uint256 _platformRenewPDRFee,
        uint256 _platformRevenueFee,
        uint256 _royaltyFee,
        address _platformFeeReceiver,
        address _royaltiesReceiver,
        address _admin,
        uint256 _buyerFee,
        uint256 _sellerFee
    ) external checkInitialized{
        require(_buyerFee + _sellerFee == 10000, "Incorrect amount");
        nftcontract_init(_admin);
        supportsInterface(bytes4(keccak256("ERC1155")));
        royaltyFee = _royaltyFee;
        platformPrimaryRentPDRFee = _platformPrimaryRentPDRFee;
        platformSecondaryRentPDRFee = _platformSecondaryRentPDRFee;
        platformRenewPDRFee = _platformRenewPDRFee;
        platformRevenueFee = _platformRevenueFee;

        platformFeeReceiver = _platformFeeReceiver;
        royaltiesReceiver = _royaltiesReceiver;
        
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
    function buyRentalPrimarySale(
        Signature.primaryOrder memory sellOrder, 
        bytes memory sellSignature,
        uint256 numberOfRentals, 
        uint128 startTime,
        uint128 endTime,
        string memory currency
    ) external payable whenNotPaused{
        require(startTime<endTime, "end time < start time");
        validateSellSignaturePrimary(sellOrder, sellSignature);

        (uint256 totalPayment, uint256 platformPayment) = calculateTotalPayment(sellOrder.payment.amount, numberOfRentals, sellOrder.numberOfTokens ,platformPrimaryRentPDRFee);

        doPlatformPayment(msg.sender, sellOrder.payment, platformPayment);
        doPaymentTransfer(msg.sender,totalPayment - platformPayment, sellOrder.maker, sellOrder.payment, true, currency);
        
        transferRentalPrimary(msg.sender, sellOrder.pdrId, numberOfRentals, startTime, endTime);
    }

    /// @notice buy Rental Secondary Sale 
    /// @param sellOrder In Order struct, sell order 
    /// @param sellSignature In bytes, signature to be verified
    /// @param numberOfRentals In uint256, The number of rentals
    /// @param startTime In unix, start Time for rental
    /// @param endTime In unix, end Time for rental
    /// @param currency In string, currency 
    function buyRentalSecondarySale(
        Signature.Order memory sellOrder,
        bytes memory sellSignature,
        uint256 numberOfRentals, 
        uint128 startTime, 
        uint128 endTime,
        string memory currency
    ) external payable whenNotPaused{
        require(startTime<endTime, "end time < start time");
        Rental memory rental = getRentalDetails(sellOrder.pdrId, sellOrder.rentalId);
        require(block.timestamp >= rental.startTime && block.timestamp < rental.endTime, "Expired");
        
        validateSellSignature(sellOrder, sellSignature);

        (uint256 totalPayment, uint256 platformPayment) = calculateTotalPayment(sellOrder.payment.amount, numberOfRentals, sellOrder.numberOfTokens ,platformPrimaryRentPDRFee);

        doPlatformPayment(msg.sender, sellOrder.payment, platformPayment);
        doPaymentTransfer(msg.sender, totalPayment - platformPayment, sellOrder.maker, sellOrder.payment, true, currency);
        transferRentalSecondary(msg.sender, sellOrder.rentalId, sellOrder.pdrId, numberOfRentals, startTime, endTime);
    }

    /// @notice renew Rental
    /// @param renewOrderValue In Order struct, sell order 
    /// @param renewSignature In bytes, signature to be verified
    /// @param rentalId In uint256, rwo Id to be renewed
    /// @param startTime In unix, start Time for rental
    /// @param endTime In unix, end Time for rental
    /// @param currency In string, currency
    function renewRental(
        Signature.renewOrder memory renewOrderValue,
        bytes memory renewSignature,
        uint256 rentalId,
        uint128 startTime,
        uint128 endTime,
        string memory currency
    ) public payable whenNotPaused{
        require(msg.sender == getRentalOwner(renewOrderValue.pdrId, rentalId),"Only rental owner");
        require(startTime<endTime, "end time < start time");
        validateRenewSignature(renewOrderValue, renewSignature);
        
        (uint256 totalPayment, uint256 platformPayment) = calculateTotalPayment(renewOrderValue.payment.amount, getRentalDetails(renewOrderValue.pdrId, rentalId).amount, renewOrderValue.numberOfTokens, platformRenewPDRFee);
        doPlatformPayment(msg.sender, renewOrderValue.payment, platformPayment);
        doPaymentTransfer(msg.sender, totalPayment - platformPayment, renewOrderValue.maker, renewOrderValue.payment, true, currency);
        updateRental(renewOrderValue.pdrId, rentalId, startTime, endTime);
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
        Signature.Payment memory payment,
        string memory currency
    ) public payable whenNotPaused{
        require(getTokenType(pdrId) == TokenType.PDR, "Incorrect pdr");
        //get rental ids
        uint256[] memory rentals = getRentalFromPDR(pdrId);
        address ownerRwo = getRwoOwner(getRwoFromPdr(pdrId));
        require(msg.sender == ownerRwo || msg.sender == owner(), "Only owner/ownerNft");

        uint256 numberOfTokens = balanceOf(ownerRwo, pdrId);
        uint256 fee;
        uint256 remainingPayment;

        (uint256 totalPayment, uint256 platformPayment) = calculateTotalPayment(payment.amount,  amountPerNFT, numberOfTokens, platformRevenueFee);
        doPlatformPayment(msg.sender, payment, platformPayment);
        for(uint256 i=0; i<rentals.length; i++){
            address renter = getRentalOwner(pdrId, rentals[i]);
            if(searchIfRentalOwnerMatches(accounts, renter)){
                
                fee = (totalPayment - platformPayment) * balanceOfRental(pdrId, rentals[i]);
                fee = fee / numberOfTokens;
                remainingPayment += fee;
                doPaymentTransfer(msg.sender, fee, renter, payment, false, currency);
            }
        }
        if(msg.sender != ownerRwo){
            doPaymentTransfer(msg.sender, totalPayment - platformPayment - remainingPayment , ownerRwo, payment, false, currency);
        }
    }

    /// @notice Calculate total payment
    /// @param amount In uint256, the amount 
    /// @param numberOfRentals In uint256, number of rentals 
    /// @param numberOfTokens  In uint256, number of tokens
    /// @param platformFee In uint256, platform fee 
    function calculateTotalPayment(
        uint256 amount,
        uint256 numberOfRentals,
        uint256 numberOfTokens,
        uint256 platformFee
    ) internal view returns(uint256, uint256){
        amount = (amount * numberOfRentals) / numberOfTokens;
        return (amount + ((amount * platformFee * buyerFee) / 100000000), ((amount * platformFee) / 10000) );
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

    /// @notice Validate signature
    /// @param digestKeccak In bytes abi encoding of struct
    /// @param sellSignature In bytes32, sell signature to be verified with
    /// @param maker Address of signature owner
    function validateSignature(
        bytes memory digestKeccak, 
        bytes memory sellSignature, 
        uint256 salt, 
        address maker
    ) internal view{
        if (salt == 0) revert("Invalid salt");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(digestKeccak)
            )
        );

        address signer = digest.recover(sellSignature);
        if(signer == address(0) || signer != maker) revert InvalidSignature();
    }

    /// @notice Validate sell signature
    /// @param sellOrder In order struct, sell order
    /// @param sellSignature In bytes32, sell signature to be verified with
    function validateSellSignature(
        Signature.Order memory sellOrder, 
        bytes memory sellSignature
    ) internal view{
        bytes memory digestKeccak = abi.encode(
                    Signature.SELL_ORDER_TYPEHASH,
                    sellOrder.maker, 
                    sellOrder.rentalId,
                    sellOrder.pdrId, 
                    sellOrder.numberOfTokens,
                    sellOrder.salt,
                    Signature.paymentHash(sellOrder.payment)
                    );
        validateSignature(digestKeccak, sellSignature, sellOrder.salt, sellOrder.maker);  
    }

    /// @notice Validate sell signature
    /// @param sellOrder In order struct, sell order
    /// @param sellSignature In bytes32, sell signature to be verified with
    function validateSellSignaturePrimary(
        Signature.primaryOrder memory sellOrder, 
        bytes memory sellSignature
    ) internal view{
        bytes memory digestKeccak = abi.encode(
                    Signature.SELL_ORDER_PRIMARY_TYPEHASH, 
                    sellOrder.maker,
                    sellOrder.pdrId, 
                    sellOrder.numberOfTokens,
                    sellOrder.salt,
                    Signature.paymentHash(sellOrder.payment)
                    );
        validateSignature(digestKeccak, sellSignature, sellOrder.salt, sellOrder.maker);          
    }

    /// @notice Validate renew signature
    /// @param renewOrderValue In order struct, renew order
    /// @param renewSignature In bytes32, renew signature to be verified with
    function validateRenewSignature(
        Signature.renewOrder memory renewOrderValue, 
        bytes memory renewSignature
    ) internal view{
        bytes memory digestKeccak = abi.encode(
                    Signature.RENEW_ORDER_TYPEHASH, 
                    renewOrderValue.maker,
                    renewOrderValue.rentalId,
                    renewOrderValue.pdrId, 
                    renewOrderValue.numberOfTokens,
                    renewOrderValue.salt,
                    Signature.paymentHash(renewOrderValue.payment)
                    );
        validateSignature(digestKeccak, renewSignature, renewOrderValue.salt, renewOrderValue.maker); 
    }

    /// @notice Platform payment in erc20/matic
    /// @param from Address of account making the transfer
    /// @param payment Payment struct
    /// @param platformPayment In uint256, platform payment to be made
    function doPlatformPayment(
        address from, 
        Signature.Payment memory payment, 
        uint256 platformPayment
    ) internal{
        // Transfer platform fees
        if (payment.paymentClass == Signature.MATIC_PAYMENT_CLASS) {
            if(msg.value < platformPayment) revert("Insufficient payment");   

            // Pay platform fee
            Signature.transferMatic(platformFeeReceiver, platformPayment);
        } else if( payment.paymentClass == Signature.ERC20_PAYMENT_CLASS){
            (address token) = abi.decode(payment.data, (address));
            
            // Pay platform fee
            IERC20(token).transferFrom(from, platformFeeReceiver, platformPayment);
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
        uint256 totalPayment, 
        address seller, 
        Signature.Payment memory payment,
        bool isRoyalty,
        string memory currency
    ) internal {
        // Transfer platform fees
        uint256 remainingPayment = totalPayment;
        uint256 currentPayment;

        if (payment.paymentClass == Signature.MATIC_PAYMENT_CLASS) {
            if(msg.value < totalPayment) revert("Insufficient payment");
            if(isRoyalty){
                // Transfer royalties
                currentPayment = (remainingPayment*royaltyFee) / 10000;
                Signature.transferMatic(royaltiesReceiver, currentPayment/2);
                Signature.transferMatic(owner(), currentPayment/2);
                remainingPayment -= currentPayment;       
            }
            // Transfer remaining payment to seller
            Signature.transferMatic(seller, remainingPayment);
        } else if( payment.paymentClass == Signature.ERC20_PAYMENT_CLASS){
            (address token) = abi.decode(payment.data, (address));
            if(isRoyalty){
                // Transfer royalties
                currentPayment = (remainingPayment*royaltyFee) / 10000;

                IERC20(token).transferFrom(from, royaltiesReceiver, currentPayment/2);
                IERC20(token).transferFrom(from, owner(), currentPayment/2);
                remainingPayment -= currentPayment;
            }
            // Transfer remaining payment to seller
            IERC20(token).transferFrom(from, seller, remainingPayment);
        } else{
            emit FiatPayment(totalPayment, currency);
        }
    }

    /// @notice set platform primary rent fee
    /// @param _platformPrimaryRentPDRFee In uint256, new platform primary rent fee
    function setPlatformPrimaryRentPDRFee(
        uint256 _platformPrimaryRentPDRFee
    ) external onlyOwner whenNotPaused{
        platformPrimaryRentPDRFee = _platformPrimaryRentPDRFee;
    }

    /// @notice set platform secondary rent fee
    /// @param _platformSecondaryRentPDRFee In uint256, new platform secondary rent fee
    function setPlatformSecondaryRentPDRFee(
        uint256 _platformSecondaryRentPDRFee
    ) external onlyOwner whenNotPaused{
        platformSecondaryRentPDRFee = _platformSecondaryRentPDRFee;
    }

    /// @notice set platform renew fee
    /// @param _platformRenewPDRFee In uint256, new platform renew fee
    function setPlatformRenewPDRFee(
        uint256 _platformRenewPDRFee
    ) external onlyOwner whenNotPaused{
        platformRenewPDRFee = _platformRenewPDRFee;
    }

    /// @notice set platform fee
    /// @param _platformRevenueFee In uint256, new platform revenue fee
    function setPlatformRevenueFee(
        uint256 _platformRevenueFee
    ) external onlyOwner whenNotPaused{
        platformRevenueFee = _platformRevenueFee;
    }

    /// @notice set royalty fee
    /// @param _newRoyaltyFee In uint256, new royalty fee
    function setRoyaltyFee(
        uint256 _newRoyaltyFee
    ) external onlyOwner whenNotPaused{
        royaltyFee = _newRoyaltyFee;
    }

    /// @notice set platform fee receiver
    /// @param _newPlatformFeeReceiver Address of new platform fee receiver
    function setPlatformFeeReceiver(
        address _newPlatformFeeReceiver
    ) external onlyOwner whenNotPaused{
        platformFeeReceiver = _newPlatformFeeReceiver;
    }

    /// @notice set royalty fee receiver
    /// @param _newRoyaltiesReceiver Address of new royalty fee receiver
    function setRoyaltiesReceiver(
        address _newRoyaltiesReceiver
    ) external onlyOwner whenNotPaused{
        royaltiesReceiver = _newRoyaltiesReceiver;
    }

    /// @notice set buyer and seller fee
    /// @param _newBuyerFee In uint256, new buyer fee
    /// @param _newSellerFee In uint256, new Seller fee
    function setBuyerAndSellerFee(
        uint256 _newBuyerFee,
        uint256 _newSellerFee
    ) external onlyOwner whenNotPaused{
        require(_newBuyerFee + _newSellerFee == 10000, "Incorrect amount");
        sellerFee = _newSellerFee;
        buyerFee = _newBuyerFee;
        emit SellerAndBuyerFeeSet(buyerFee, sellerFee);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./Pausable.sol";

/// @title NFT contract
/// @notice This contract mints, transfers and burns nft and rental ids
contract NFTContract is ERC1155, Ownable, Pausable{
    event RWOMinted(address to, uint256 nftId);
    event PDRMinted(address to, uint256 nftId, uint256 amount );
    event RentalMinted(address to, uint id, uint256 amount, uint128 startTime, uint128 endTime);
    event RWOBurnt(address to, uint256 nftId);
    event PDRBurnt(address to, uint256 nftId);
    event RentalBurnt(address to, uint256 rentalId);
    event RWOTransferred(address to, uint256 nftId);
    event RentalTransferred(address to, uint256 id, uint256 amount, uint128 startTime, uint128 endTime);
    event RentalRenewed(uint256 rentalId, uint128 startTime, uint128 endTime);
    
    struct Rental{
        uint256 rentalId;
        address renter;
        uint256 amount;
        uint128 startTime;
        uint128 endTime;
    }

    struct Pdr{
        uint256 pdrId;
        string uri;
    }

    struct Rwo{
        uint256 rwoId;
        address rwoOwner;
        string uri;
    }

    address public admin;
    uint256 public nftId;

    enum TokenType{RWO, PDR, NONE} //NONE is used to assign after burning

    mapping(uint256 => Rwo) public rwo;
    mapping(uint256 => Pdr) public pdr;
    // pdrId -> rentalId -> rental
    mapping(uint256 => mapping(uint256 => Rental)) public rental;

    // rwo and pdr mapping to token type
    mapping(uint256 => TokenType) internal tokenType;

    // rwo id to pdr ids
    mapping (uint256 => uint256[]) public rwoToPdr;
    // pdr id to rental ids
    mapping(uint256 => uint256[]) public pdrToRental;
    mapping(uint256 => uint256) private pdrToRentalId;
    mapping(uint256 => mapping(uint256 => uint256)) private pdrIndex;
    mapping(uint256 => uint256) private pdrRemainingAmount;
    mapping (uint256 => mapping(uint256 => uint256)) private rentalIndex;

    // pdr id to rwo id
    mapping(uint256 => uint256) public pdrToRwo;
    bool public initialized;
    
    modifier onlyAdminOrOwner {
        require(owner() == msg.sender || admin == msg.sender, "Only admin/owner");
        _;
    }

    modifier checkInitialized(){
        if(initialized) revert("Already initialized");
        _;
    }

    function nftcontract_init(address _admin) public checkInitialized{
        initialized = true;
        pausable_init();
        ownable_init();
        admin = _admin;
    }


    /// @notice Mints Rwo by onlyAdminOrOwner
    /// @param to Address to which rwo will be minted
    /// @param uri string, for metadata uri
    function mintRWO(
        address to,     
        string calldata uri
    ) public onlyAdminOrOwner whenNotPaused{
        nftId++;
        tokenType[nftId] = TokenType.RWO;
        _mint(to, nftId, 1, "");

        // rwo mapping
        rwo[nftId]= Rwo(uint256(nftId), address(to), string(uri));

        // Approve owner and admin so that force transfer by onlyAdminOrOwner can be done
        setApprovalForAll(to, true);
        emit RWOMinted(to, nftId);
    }

    /// @notice Mints Pdr by onlyAdminOrOwner
    /// @param rwoId in uint256, rwo id to be linked to pdr
    /// @param amount in uint256, amount of pdr minted
    /// @param uri string, for metadata uri
    function mintPDR(
        uint256 rwoId, 
        uint256 amount, 
        string calldata uri
    ) public onlyAdminOrOwner whenNotPaused{
        if(getTokenType(rwoId) != TokenType.RWO) revert("Incorrect Rwo id");
        nftId++;
        tokenType[nftId] = TokenType.PDR;

        // pdr mapping
        pdr[nftId] = Pdr(uint256(nftId), string(uri));

        address ownerRwo = getRwoOwner(rwoId);

        rwoToPdr[rwoId].push(nftId);
        pdrToRwo[nftId] = rwoId;
        pdrIndex[rwoId][nftId] = getPdrFromRwo(rwoId).length -1;

        pdrRemainingAmount[nftId] = amount;

        _mint(ownerRwo, nftId, amount, "");
        emit PDRMinted(ownerRwo, nftId, amount);
    }

    /// @notice  Mints Rental Ids
    /// @param pdrId already minted pdr id to be linked to rental
    /// @param to Address to which renter will be minted
    /// @param amount in uint256, amount of rentals minted
    /// @param startTime in unix, time from which rental will be minted
    /// @param endTime in unix, time till which rental will be minted
    function mintRentalToken(
        uint256 pdrId, 
        address to, 
        uint256 amount,
        uint128 startTime, 
        uint128 endTime 
    ) internal{
        uint256 rentalId = pdrToRentalId[pdrId];
        rental[pdrId][rentalId] = Rental(rentalId, to, amount, startTime, endTime);
        rentalIndex[pdrId][rentalId] = getRentalFromPDR(pdrId).length;

        pdrToRentalId[pdrId] += 1;
        // forward mapping
        pdrToRental[pdrId].push(rentalId);

        //set approval for owner and admin
        setApprovalForAll(to, true);
        emit RentalMinted(to, rentalId, amount, startTime, endTime );
    }

    /// @notice Transfers rental in primary sale
    /// @param to Address to which renter will be transferred
    /// @param pdrId already minted pdr id to be linked to transferred
    /// @param amount in uint256, amount of rentals transferred
    /// @param startTime in unix, time from which rental will be transferred
    /// @param endTime in unix, time till which rental will be transferred
    function transferRentalPrimary(
        address to,
        uint256 pdrId,
        uint256 amount,
        uint128 startTime,
        uint128 endTime
    ) internal{
        mintRentalToken(pdrId, to, amount, startTime, endTime);
        if(amount >= pdrRemainingAmount[pdrId]){
            pdrRemainingAmount[pdrId] = 0;
        } else{
            pdrRemainingAmount[pdrId] -= amount;
        }
    }

    /// @notice Transfers rental in secondary sale
    /// @param to Address to which renter will be transferred
    /// @param pdrId already minted pdr id to be linked to transferred
    /// @param amount in uint256, amount of rentals transferred
    /// @param startTime in unix, time from which rental will be transferred
    /// @param endTime in unix, time till which rental will be transferred
    function transferRentalSecondary(
        address to,
        uint256 rentalId,
        uint256 pdrId,
        uint256 amount,
        uint128 startTime,
        uint128 endTime
    ) internal{
        //Balance check
        require(amount <= balanceOfRental(pdrId, rentalId), "Insufficient balance");
        rental[pdrId][rentalId].amount -= amount;
        if(amount >= pdrRemainingAmount[pdrId]){
            pdrRemainingAmount[pdrId] = 0;
        } else{
            pdrRemainingAmount[pdrId] -= amount;
        }
        mintRentalToken(pdrId, to, amount, startTime, endTime);
    }

    /// @notice Transfer Rwo id by admin/owner/RWOOwner
    /// @param to Address to which Rwo id is to be transferred
    /// @param rwoId In uint256, Rwo id which is to be transferred
    function transferRWO(
        address to,
        uint256 rwoId
    ) public whenNotPaused{
        require(getTokenType(rwoId) == TokenType.RWO, "Only RWO");
        
        address rwoOwner = getRwoOwner(rwoId);
        require(msg.sender == admin || msg.sender == owner() || msg.sender == rwoOwner, "Only admin/owner/RWOOwner");

        uint[] memory pdrId = new uint[](1);
        uint256[] memory pdrAmount = new uint[](1);
        for(uint256 i=0; i< getPdrFromRwo(rwoId).length; i++){
            pdrId[0] = rwoToPdr[rwoId][i];
            pdrAmount[0] = balanceOf(rwoOwner, pdrId[0]);
            safeBatchTransferFrom(rwoOwner, to, pdrId, pdrAmount, "");
        }

        // set approval
        setApprovalForAll(to, true);
        rwo[rwoId].rwoOwner = to;
        safeTransferFrom(rwoOwner, to, rwoId, balanceOf(rwoOwner, rwoId), "");
        emit RWOTransferred(to, rwoId);
    }

    /// @notice Transfers Rwo Id by admin/owner
    /// @param rentalId in uint256, Rental id which is to be transferred
    /// @param pdrId in uint256, Pdr id which is linked to Rental id
    /// @param to Address to which Rental id is to be transferred
    function transferRental(
        uint256 rentalId,
        uint256 pdrId,
        address to
    ) public onlyAdminOrOwner whenNotPaused{
        rental[pdrId][rentalId].renter = to;
        emit RentalTransferred(to, rentalId, rental[pdrId][rentalId].amount, rental[pdrId][rentalId].startTime, rental[pdrId][rentalId].endTime);
    }

    /// @notice Calculate tree age in years, rounded up, for live trees
    /// @param pdrId In uint256, Pdr id which is linked to Rental id
    /// @param rentalId In uint256, Rental id of which start and end time have to be updated
    /// @param startTime In unix, new start time
    /// @param endTime In unix, new end time
    function updateRental(
        uint256 pdrId,
        uint256 rentalId,
        uint128 startTime,
        uint128 endTime
    ) internal{
        rental[pdrId][rentalId].startTime = startTime;
        rental[pdrId][rentalId].endTime = endTime;
        emit RentalRenewed(rentalId, startTime, endTime);
    }

    /// @notice Burns Rwo by admin/owner/RWOOwner
    /// @param nftID In uint256, rwoId to be burnt
    function burnNFTId(
        uint256 nftID
    ) public whenNotPaused{
        require(msg.sender == admin || msg.sender == owner() || msg.sender == getRwoOwner(nftID), "Only admin/owner/RWOOwner");

        if(tokenType[nftID] == TokenType.RWO){
            address ownerRwo = getRwoOwner(nftID);
            _burn(ownerRwo, nftID, balanceOf(ownerRwo, nftID));
            
            for(uint256 i=0; i< getPdrFromRwo(nftID).length; i++){
                uint pdrId = rwoToPdr[nftID][i];
                burnPdrNFT(pdrId, ownerRwo, nftID);
                emit PDRBurnt(ownerRwo, pdrId);
            }
            delete rwo[nftID];
            tokenType[nftID] = TokenType.NONE;
        } else if(tokenType[nftID] == TokenType.PDR){
            burnPDR(nftID); 
        } else{
            revert("Id doesnt exist");
        }
        emit RWOBurnt(rwo[nftID].rwoOwner, nftID);
    }

    /// @notice Burns Pdr id
    /// @param pdrId In uint256, pdr id to be burnt
    /// @param ownerRwo Address of owner of Rwo
    function burnPdrNFT(
        uint256 pdrId, 
        address ownerRwo,
        uint256 rwoId
    ) internal{
        uint amount = balanceOf(ownerRwo, pdrId);
        updatePdrMapping(pdrId, rwoId);
        for(uint i=0; i< getRentalFromPDR(pdrId).length; i++){
            uint256 rentalId = pdrToRental[pdrId][i];
            // burn rental ids also
            delete rentalIndex[pdrId][rentalId];
            delete rental[pdrId][rentalId];
        }
        delete pdrToRental[pdrId];
        delete pdrToRentalId[pdrId];
        tokenType[pdrId] = TokenType.NONE;

        // Update pdr and rwo mappings
        delete pdrToRwo[pdrId]; 
        _burn(ownerRwo, pdrId, amount); 
        emit PDRBurnt(ownerRwo, pdrId);   
    }

    /// @notice Burns Pdr id by amount of unrented pdr
    /// @param pdrId In uint256, pdr id to be burnt
    function burnPDR(
        uint256 pdrId
    ) internal{
        uint rwoId = getRwoFromPdr(pdrId);
        address ownerRwo = getRwoOwner(rwoId);
        uint amount = balanceOf(ownerRwo, pdrId);
        if(pdrRemainingAmount[pdrId] != 0){
            pdrRemainingAmount[pdrId] = 0;
            _burn(ownerRwo, pdrId, pdrRemainingAmount[pdrId]);
            emit PDRBurnt(ownerRwo, pdrId);
            return;
        }
        
        updatePdrMapping(pdrId, rwoId);
        for(uint i=0; i< getRentalFromPDR(pdrId).length; i++){
            uint256 rentalId = pdrToRental[pdrId][i];
            // burn rental ids also
            delete rentalIndex[pdrId][rentalId];
            delete rental[pdrId][rentalId];
        }
        delete pdrToRental[pdrId];
        delete pdrToRentalId[pdrId];
        tokenType[pdrId] = TokenType.NONE;

        // Update pdr and rwo mappings
        delete pdrToRwo[pdrId]; 
        _burn(ownerRwo, pdrId, amount); 
        emit PDRBurnt(ownerRwo, pdrId);      
    }

    /// @notice Updates pdr index and rwoToPdr mapping
    /// @param pdrId In uint256, pdr id to be updated
    function updatePdrMapping(uint256 pdrId, uint rwoId) internal{
        //update index for pdr and rwo mapping
        uint index = pdrIndex[rwoId][pdrId];
         
        uint length = getPdrFromRwo(rwoId).length;
        uint swapRwoId = rwoToPdr[rwoId][length-1];
        rwoToPdr[rwoId][index] = rwoToPdr[rwoId][length-1];
        pdrIndex[rwoId][swapRwoId] = index;

        delete pdrIndex[rwoId][index];
        rwoToPdr[rwoId].pop();
    }

    /// @notice Burns rental id
    /// @param rentalId In uint256, rental id to be burnt
    /// @param pdrId In uint256, pdr id
    /// @param amount amount of rental to be burnt
    function burnRental(
        uint256 rentalId, 
        uint256 pdrId,
        uint256 amount
    ) public whenNotPaused{
        require(amount <= getRentalDetails(pdrId, rentalId).amount, "Incorrect amount");
        uint rwoId = getRwoFromPdr(pdrId); 
        require(msg.sender == admin || msg.sender == owner() || msg.sender == getRwoOwner(rwoId), "Only admin/owner/RWOOwner");
        
        if(amount != getRentalDetails(pdrId, rentalId).amount){
            rental[pdrId][rentalId].amount -= amount;
            emit RentalBurnt(rental[pdrId][rentalId].renter, rentalId);
            return;
        }

        // update rental and pdr mappings
        uint index = rentalIndex[pdrId][rentalId];
        uint length = getRentalFromPDR(pdrId).length;
        uint swapRentalId = pdrToRental[pdrId][length-1];

        pdrToRental[pdrId][index] = pdrToRental[pdrId][length-1];
        rentalIndex[pdrId][swapRentalId] = index;
        
        delete rentalIndex[pdrId][index];
        pdrToRental[pdrId].pop();
        pdrRemainingAmount[pdrId] += amount;

        emit RentalBurnt(getRentalDetails(pdrId,rentalId).renter, rentalId);
        delete rental[pdrId][rentalId];
    }

    /// @notice Set approval for owner and admin
    /// @param from Address of account to set approval
    /// @param approved Bool value
    function setApprovalForAll(address from, bool approved) public virtual override whenNotPaused {
        _setApprovalForAll(from, owner(), approved);
        _setApprovalForAll(from, admin, approved);
    }

    /// @notice Get token type
    /// @param tokenId In uint256, token id
    /// @return TokenType either rwo or pdr as type of token id
    function getTokenType(
        uint256 tokenId
    ) public view whenNotPaused returns(TokenType) {
        if(tokenId > nftId || tokenId == 0) revert("Id doesnt exist");
        return tokenType[tokenId];
    }

    /// @notice Calculates balance of rental
    /// @param pdrId In uint256, pdr id
    /// @param rentalId In uint256, rental id
    /// @return balanceOfRental In uint256, returns rental balance
    function balanceOfRental(
        uint256 pdrId, 
        uint256 rentalId
    ) public view whenNotPaused returns(uint256){
        if(getRentalDetails(pdrId,rentalId).startTime <= block.timestamp && getRentalDetails(pdrId,rentalId).endTime >= block.timestamp){
            return getRentalDetails(pdrId,rentalId).amount;
        }
        return 0;
    }

    /// @notice Get rental nft balance details
    /// @param pdrId In uint256, pdr id
    /// @param rentalId In uint256, rental id
    /// @return nftOwner Address of owner
    function getRentalNFTBalanceDetails(
        uint256 pdrId, 
        uint256 rentalId
    ) public view whenNotPaused returns(address){
        if(getRentalDetails(pdrId,rentalId).startTime <= block.timestamp && getRentalDetails(pdrId,rentalId).endTime >= block.timestamp){
            return getRentalDetails(pdrId,rentalId).renter;
        }
        uint256 rwoId = getRwoFromPdr(pdrId);
        return getRwoOwner(rwoId);
    }

    /// @notice Get rental id owner
    /// @param pdrId In uint256, pdr id
    /// @param rentalId In uint256, rental id
    /// @return rentalOwner Address of rental id owner
    function getRentalOwner(
        uint256 pdrId,
        uint256 rentalId
    ) public view whenNotPaused returns(address){
        return getRentalDetails(pdrId,rentalId).renter;
    }

    /// @notice Get rwo id owner
    /// @param rwoId In uint256, rwo id
    /// @return rwoOwner Address of rwo id owner
    function getRwoOwner(
        uint256 rwoId
    ) public view whenNotPaused returns(address){
        return rwo[rwoId].rwoOwner;
    }

    /// @notice Get rental details
    /// @param pdrId In uint256, pdr id
    /// @param rentalId In uint256, rental id
    /// @return rentalDetails In rental, returns details like rentalId, renter, amount, startTime, endTime
    function getRentalDetails(
        uint256 pdrId,
        uint256 rentalId
    ) public view whenNotPaused returns(Rental memory){
        return rental[pdrId][rentalId];
    }

    /// @notice Get Pdr id from Rwo id
    /// @param rwoId In uint256, rwo id
    /// @return pdrIds In uint256[], all Pdr ids associated to rwo id 
    function getPdrFromRwo(
        uint256 rwoId
    ) public view whenNotPaused returns(uint256[] memory) {
        return rwoToPdr[rwoId];
    }

    /// @notice Get Rentals from Pdr id
    /// @param pdrId In uint256, pdr id
    /// @return rentalIds In uint256[], returns all rental ids associated to pdr
    function getRentalFromPDR(
        uint256 pdrId
    ) public view whenNotPaused returns(uint256[] memory) {
        return pdrToRental[pdrId];
    }

    /// @notice Get Rwo id from pdr id
    /// @param pdrId In uint256, pdr id
    /// @return rwoId In uint256, rwo id associated to pdr 
    function getRwoFromPdr(
        uint256 pdrId
    ) public view whenNotPaused returns(uint256){
        return pdrToRwo[pdrId];
    }

    /// @notice Sets new admin by owner
    /// @param newAdmin Address of new admin
    function setAdmin(
        address newAdmin
    ) public onlyOwner whenNotPaused{
        admin = newAdmin;
    }

    /// @notice Checks balance of multiple accounts and nft ids
    /// @param accounts Addresses of accounts
    /// @param nftIds In uint256[], list of nft ids
    function getNFTBatchBalance(
        address[] memory accounts, 
        uint256[] memory nftIds
    ) public view whenNotPaused returns (uint256[] memory){
        return balanceOfBatch(accounts, nftIds);
    }

    /// @notice Pauses the contract by only owner
    function pause() public whenNotPaused onlyOwner{
        _pause();
    }

    /// @notice Unpauses the contract by only owner
    function unpause() public whenPaused onlyOwner{
        _unpause();
    }

    /// @notice Checks if the contract is paused
    function isContractPaused() public view virtual returns (bool) {
        return paused();
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSA.sol";

error InvalidSignature();

/// @title Darabase contract
/// @notice For buying rentals in sale, distributing revenue and renewing rentals
library Signature{
    struct Payment{
        bytes4 paymentClass;
        uint256 amount;
        bytes data;
    }

    struct primaryOrder{
        address maker;
        uint256 pdrId;
        uint256 numberOfTokens;
        uint256 salt;
        Payment payment;
    }

    struct Order{
        address maker;
        uint256 rentalId;
        uint256 pdrId;
        uint256 numberOfTokens;
        uint256 salt;
        Payment payment;
    }

    struct renewOrder{
        address maker;
        uint256 rentalId;
        uint256 pdrId;
        uint256 numberOfTokens;
        uint256 salt;
        Payment payment;
    }

    bytes4 constant public MATIC_PAYMENT_CLASS = bytes4(keccak256("MATIC")); // 0xa6a7de01
    bytes4 constant public ERC20_PAYMENT_CLASS = bytes4(keccak256("ERC20")); // 0x8ae85d84
    bytes32 constant PAYMENT_TYPEHASH = keccak256(
        "Payment(bytes4 paymentClass,uint256 amount,bytes data)"
    );
    bytes32 internal constant SELL_ORDER_PRIMARY_TYPEHASH =
        keccak256("SellOrder(address maker,uint256 pdrId,uint256 numberOfTokens,uint256 salt,Payment payment)Payment(bytes4 paymentClass,uint256 amount,bytes data)");
    bytes32 internal constant SELL_ORDER_TYPEHASH =
        keccak256("SellOrder(address maker,uint256 rentalId,uint256 pdrId,uint256 numberOfTokens,uint256 salt,Payment payment)Payment(bytes4 paymentClass,uint256 amount,bytes data)");
    bytes32 internal constant RENEW_ORDER_TYPEHASH =
        keccak256("RenewOrder(address maker,uint256 rentalId,uint256 pdrId,uint256 numberOfTokens,uint256 salt,Payment payment)Payment(bytes4 paymentClass,uint256 amount,bytes data)");

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
        require(success, "transfer failed");
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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function ownable_init() public {
        _transferOwnership(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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
    mapping(uint256 => mapping(address => uint256)) private _balances;

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
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
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
     * @dev Initializes the contract in unpaused state.
     */
    function pausable_init() public{
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