/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);  // maybe use safetransfer? idk
}

contract FastlaneJITAuctionAlphaTest {

    struct BidData {
        uint256 bidAmount;
        uint256 pflFee;
        bytes32 oppTxHash;
        address searcherToAddress;
        address searcherEOA;
        uint64 blockNumber;
        address validator;
        address initEOA;
        uint256 gasPrice;
        bool initialized;
        bool filled;
        bool refunded;
    }

    struct ValidatorData {
        bool initialized;
        bool participating;
        uint256 balance;
        uint256 balancePaid;
        uint64 lastBlockPaid;
        address payee;
    }

    struct PFLFeeCollector {
        uint256 collected;
        uint256 uncollected;
        uint256 gross;
        uint256 refunded;
        uint256 fee;
        uint256 base;
        uint256 validatorPayable;
        uint256 pflPayable;
    }

    event NewAuction(
        bytes32 indexed oppTxHash,
        address indexed winningSearcherContract,
        address indexed validator
    );

    address public immutable owner;
    
    constructor()  {
        owner = msg.sender;
        }

    uint256 auctionArrayIndex = 0;
    uint256 refundArrayIndex = 0;
    uint256 totalAuctionCount = 0;
    uint256 totalRefundCount = 0;
    uint256 initBidGasUsed = 150_000;
    uint256 immutable arrayMaxSize = 256;
    
    bytes32 nilBytes32 = bytes32(0);

    mapping(bytes32 => BidData) bidMap;
    mapping(address => ValidatorData) validatorMap;
    mapping(address => bool) initAddressMap;

    PFLFeeCollector feeCollector = PFLFeeCollector(0, 0, 0, 0, 0, 1_000_000, 0, 0);

    bytes32[256] auctionOppHashes; // array of last 256 PFL-targetted opp hashes
    bytes32[256] refundOppHashes; // array of last 256 PFL-targetted opp hashes with refunds

    function addValidator(address validator, address payee) public returns (bool) {
        require(msg.sender == owner, 'err - owner only');
        require(!validatorMap[validator].initialized, 'err - validator already initialized');
        validatorMap[validator] = ValidatorData(true, true, 0, 0, 0, payee);
        return validatorMap[validator].participating;
    }

    function removeValidator(address validator) public returns (bool) {
        require(msg.sender == owner, 'err - owner only');
        require(validatorMap[validator].initialized, 'err - validator never initialized');
        require(validatorMap[validator].participating, 'err - validator already deactivated');
        validatorMap[validator].participating = false;
        if (!validatorMap[validator].participating) {
            return true;
        } else {
            return false;
        }
    }

    function addInitEOA(address eoa) public returns (bool) {
        // adds EOAs that can initialize a PFL auction slot
        require(msg.sender == owner || initAddressMap[msg.sender], 'err - owner or approved EOAs only');
        initAddressMap[eoa] = true;
        return initAddressMap[eoa];
    }

    function initBid(
        bytes32 oppTxHash, 
        address validator, 
        address searcherToAddress, 
        address searcherEOA, 
        uint256 gasPrice, 
        uint256 bidAmountRaw
    ) public {
        // PFL EOAs will submit a tx that will initialize receipt of the winning bid
        // note: bidAmountRaw is the bidAmount before the PFL EOA is refunded

        require(msg.sender == owner || initAddressMap[msg.sender], 'err - owner or approved EOAs only');
        require(validator == block.coinbase, 'err - incorrect validator');
        require(validatorMap[validator].participating, 'err - nonparticipating validator');
        require(!bidMap[oppTxHash].initialized, 'err - oppTx already auctioned');
        //require(bidAmountRaw > gasPrice * initBidGasUsed, 'err - bid amount is smaller than initBid gas cost');
        // altered for expanded alpha test
        require(bidAmountRaw != 0, 'err - bid amount is smaller than initBid gas cost');

        // subtract the pfl initialization gas cost from the value to get the bidAmount
        // uint256 _bidAmount = msg.value - (tx.gasprice * initBidGasUsed);
        // disabled for alpha test

        // handle protocol fee math
        uint256 _pflFee = bidAmountRaw * feeCollector.fee / feeCollector.base;

        // subtract the pfl initialization gas cost from the value to get the bidAmount
        // uint256 _bidAmount = msg.value - (tx.gasprice * initBidGasUsed);
        // disabled for alpha test
        uint256 _bidAmount = bidAmountRaw - _pflFee;
        
        // initialize the bidMap
        bidMap[oppTxHash] = BidData(_bidAmount, _pflFee, oppTxHash, searcherToAddress, searcherEOA, uint64(block.number), validator, msg.sender, gasPrice, true, false, false);
        
        // update the auction hash array
        totalAuctionCount++;
        if (auctionArrayIndex < arrayMaxSize) {
            auctionOppHashes[auctionArrayIndex++] = oppTxHash;
        } else {
            auctionArrayIndex = 0;
            auctionOppHashes[auctionArrayIndex] = oppTxHash;
        }

        emit NewAuction(oppTxHash, searcherToAddress, validator);
    }

    function submitBid(
        bytes32 oppTxHash, 
        address validator, 
        address searcherToAddress
    ) public payable {
        // bid submission, called by a searcher EOA. Must first be initialized by a PFL EOA

        // grab the initialized bid data
        BidData memory bidData = bidMap[oppTxHash];

        // safety checks to make sure this bid is the initialized bid
        require(bidData.searcherEOA == msg.sender, 'err - searcher EOA was not winner of auction');
        require(validator == block.coinbase, 'err - incorrect validator');
        require(validatorMap[validator].participating, 'err - nonparticipating validator');
        require(bidData.validator == validator, 'err - validator does not match init tx validator');
        uint64 blockNumber = uint64(block.number);
        require(bidData.blockNumber == blockNumber, 'err - init and searcher bid landed in separate blocks');
        require(bidData.initialized && !bidData.filled, 'err - oppTx already auctioned');
        require(tx.gasprice == bidData.gasPrice, 'err - wrong gasPrice in transaction parameters');
        require(bidData.searcherToAddress == searcherToAddress, 'err - searcherToAddress mismatch between initBid and submitBid');
        // require(msg.value > tx.gasprice * initBidGasUsed, 'err - msg value is smaller than initBid gas cost');
        // removed for expanded alpha test
        uint256 _bidAmountRaw = msg.value;
        require(_bidAmountRaw == bidData.bidAmount + bidData.pflFee, 'err - actual bid does not match expected bid');

        // subtract the pfl initialization gas cost from the value to get the bidAmount
        // uint256 _bidAmount = msg.value - (tx.gasprice * initBidGasUsed);
        // disabled for alpha test

        // handle protocol fee math
        uint256 _pflFee = _bidAmountRaw * feeCollector.fee / feeCollector.base;
        uint256 _bidAmount = _bidAmountRaw - _pflFee;

        // update the validatorMap w/ the validator changes
        validatorMap[validator].balance += (_bidAmount - _pflFee);

        // update fee collector 
        feeCollector.validatorPayable += (_bidAmount - _pflFee);
        feeCollector.pflPayable += _pflFee;
        feeCollector.gross += _bidAmount;

        // refund the PFL EOA that initialized the bid (thankfully this is on polygon)
        // payable(bidData.initEOA).transfer(tx.gasprice * initBidGasUsed);
        // disabled for alpha test

        // update the bidMap w/ the bid info
        bidData.filled = true;
        bidMap[oppTxHash] = bidData;
    }

    function refundBid(bytes32 oppTxHash) public {
        require(msg.sender == owner, 'err - owner only');
        
        // get / update bid information
        BidData memory bidData = bidMap[oppTxHash];
        require(bidData.initialized && bidData.filled, 'err - bid never completed');
        require(!bidData.refunded, 'err - bid already refunded');
        bidData.refunded = true;

        // grab some important variables
        uint256 _bidAmount = bidData.bidAmount;
        uint256 _pflFee = bidData.pflFee;
        address _validator = bidData.validator;

        // get / update validator information
        ValidatorData memory validatorData = validatorMap[_validator];
        
        uint256 _currentValidatorBalance = validatorData.balance;

        require(validatorData.initialized, 'err - validator never participated in PFL'); // this err message should never be possible
        require(_currentValidatorBalance >= _bidAmount - _pflFee, 'err - validator vault has insufficient funds for refund');
        require(address(this).balance >= _bidAmount, 'err - pfl contract has insufficient funds for refund 01');

        validatorData.balance = _currentValidatorBalance - _bidAmount + _pflFee;

        // update fee collector data
        uint256 _validatorPayable = feeCollector.validatorPayable;
        uint256 _pflPayable = feeCollector.pflPayable;
        require(_bidAmount - _pflFee <= _validatorPayable, 'err - insufficient funds for refund 02');
        require(_pflFee <= _pflPayable, 'err - insufficient funds for refund 03');

        feeCollector.refunded += _bidAmount;
        feeCollector.validatorPayable = _validatorPayable - _bidAmount + _pflFee;
        feeCollector.pflPayable = _pflPayable - _pflFee;

        // update the refund block array
        totalRefundCount++;
        if (refundArrayIndex < arrayMaxSize) {
            refundOppHashes[refundArrayIndex++] = oppTxHash;
        } else {
            refundArrayIndex = 0;
            refundOppHashes[refundArrayIndex] = oppTxHash;
        }

        bidMap[oppTxHash] = bidData;
        validatorMap[_validator] = validatorData;

        payable(bidData.searcherEOA).transfer(_bidAmount);
    }

    function emergencyTokenWithdraw(address _tokenAddress) public {
        require(msg.sender == owner, 'err - owner only');

        IERC20 oopsToken = IERC20(_tokenAddress);
        uint256 oopsTokenBalance = oopsToken.balanceOf(address(this));

        if (oopsTokenBalance > 0) {
            oopsToken.transferFrom(address(this), owner, oopsTokenBalance);
        }
    }

    function emergencyMaticWithdraw(uint256 amount, address recipient) public {
        require(msg.sender == owner, 'err - owner only');
        require(address(this).balance >= amount, 'err - insufficient funds for transfer');
        payable(recipient).transfer(amount);
    }

    function payValidator(uint256 amount, address validator) public {
        require(msg.sender == owner, 'err - owner only');

        ValidatorData memory validatorData = validatorMap[validator];
        
        require(validatorData.balance >= amount, 'err - validator vault has insufficient funds for payment');
        require(address(this).balance >= amount, 'err - pfl contract has insufficient funds for payment');

        // update validator data
        validatorData.balance -= amount;
        validatorData.lastBlockPaid = uint64(block.number);
        validatorData.balancePaid += amount;

        // handle fees (make available for PFL withdrawal)
        uint256 pflEscrowAdd = (feeCollector.fee * amount) / (feeCollector.base - feeCollector.fee);
        // TODO: update above math to handle scenarios where fee gets lowered / raised in between fee withdrawals
        // potentially add feeMap? (may not be necessary)
        // this could potentially cause a remainder of PFL balance to stay on contract

        feeCollector.uncollected +=  pflEscrowAdd;
        feeCollector.validatorPayable -= amount;
        feeCollector.pflPayable -= pflEscrowAdd;

        // send payment
        payable(validatorData.payee).transfer(amount);
        validatorMap[validator] = validatorData;
    }

    function collectFees(uint256 amount) public {
        require(msg.sender == owner, 'err - owner only');
        require(address(this).balance >= amount, 'err - pfl contract has insufficient funds for payment');
        require(amount <= feeCollector.uncollected, 'err - withdrawal exceeds uncollected amount');

        feeCollector.collected += amount;
        feeCollector.uncollected -= amount;

        // send payment
        payable(owner).transfer(amount);
    }

    function changeFee(uint256 fee, uint256 base) public {
        require(msg.sender == owner, 'err - owner only');
        require(base >= fee, 'err - fee exceeds base');
        feeCollector.fee = fee;
        feeCollector.base = base;
    }

    function getSearcherBidFromOpportunityHash(bytes32 oppTxHash) public view
    returns (bool, bool, uint256, uint64, address, address) {
        // returns fill status, refund status, bid amount, block number, searcher contract address, searcher eoa address
        return (bidMap[oppTxHash].filled, bidMap[oppTxHash].refunded, bidMap[oppTxHash].bidAmount, bidMap[oppTxHash].blockNumber, bidMap[oppTxHash].searcherToAddress, bidMap[oppTxHash].searcherEOA);
    }

    function getLastNAuctionTxHashes(uint256 n) public view 
    returns (bytes32[] memory hashSlice) {
        // note: goes without saying but don't run this on chain - it's a gas destroyer
        hashSlice = new bytes32[](n);
        uint256 q = 0;
        bytes32 _hash;

        for (uint256 z=1; z <= n; z++) {
            // note: current index is not initializd - last initialized index is current - 1
            if (auctionArrayIndex - z >= 0) {
                _hash = auctionOppHashes[auctionArrayIndex - z];
            }
            else {
                _hash = auctionOppHashes[arrayMaxSize + auctionArrayIndex - z];
                // for index overflow scenario
            }
            if (_hash == nilBytes32 || q > totalAuctionCount) {
                break;
            }
            hashSlice[q] = _hash;
            if (++q >= n) {
                break;
            }   
        }
        return hashSlice;
    }

    function getLastNRefundTxHashes(uint256 n) public view 
    returns (bytes32[] memory hashSlice) {
        // note: goes without saying but don't run this on chain - it's a gas destroyer
        hashSlice = new bytes32[](n);
        uint256 q = 0;
        bytes32 _hash;

        for (uint256 z=1; z <= n; z++) {
            // note: current index is not initializd - last initialized index is current - 1
            if (refundArrayIndex - z >= 0) {
                _hash = refundOppHashes[refundArrayIndex - z];
            }
            else {
                _hash = refundOppHashes[arrayMaxSize + refundArrayIndex - z];
                // for index overflow scenario
            }
            if (_hash == nilBytes32 || q > totalRefundCount) {
                break;
            }
            hashSlice[q] = _hash;
            if (++q >= n) {
                break;
            }   
        }
        return hashSlice;
    }
}