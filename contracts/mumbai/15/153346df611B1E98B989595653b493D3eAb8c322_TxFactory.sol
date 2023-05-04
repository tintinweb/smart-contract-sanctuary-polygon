// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./TxFactory.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Tx {
    using SafeMath for uint;

    address public TxFactoryContractAddress;

    string public ipfsImage;
    string item;
    uint256 price;
    string sellerPhysicalAddress;
    uint256 id;

    string buyerPhysicalAddress;

    uint256 multipleOfPrice = 2;

    uint256 sellerCollateral;
    uint256 buyerCollateral;
    uint256 costCollateral;

    uint256 tipForSeller;
    uint256 tipForBuyer;

    bool dispute;
    address buyer;
    address seller;
    bool sellerSettled;
    bool buyerSettled;
    bool pending;
    bool finalSettlement;

    error Transfer__Failed();

    constructor(
        string memory _ipfsImage,
        string memory _item,
        uint256 _price,
        string memory _sellerPhysicalAddress,
        address _sellerAddress,
        uint256 _id,
        address _TxFactoryContractAddress
    ) payable {
        require(msg.value >= _price, "You did not put enough collateral funds");

        item = _item;
        price = _price;
        sellerPhysicalAddress = _sellerPhysicalAddress;
        id = _id;

        seller = _sellerAddress;

        ipfsImage = _ipfsImage;

        TxFactoryContractAddress = _TxFactoryContractAddress;

        sellerCollateral += _price;

        TxFactory(TxFactoryContractAddress).setTransaction(
            seller,
            address(this)
        );
    }

    function purchase(string memory _buyerPhysicalAddress) public payable {
        require(
            msg.value == price * multipleOfPrice,
            "Not enough memony to purchase"
        );
        buyer=msg.sender;
        TxFactory(TxFactoryContractAddress).setBuyerTransaction(
            msg.sender,
            address(this)
        );
        TxFactory(TxFactoryContractAddress).removeFromPublicArray(
            address(this)
        );
        buyerPhysicalAddress = _buyerPhysicalAddress;
        buyer = msg.sender;
        pending = true;
        buyerCollateral = price;
        costCollateral = price;
    }

    function setDispute() public {
        require(msg.sender == buyer, "You are not authorized to dispute");
        dispute = true;
    }

    function tipSeller() public payable {
        require(msg.sender == buyer, "You are not authorized to to tip");
        tipForSeller += msg.value;
    }

    function tipBuyer() public payable {
        require(msg.sender == seller, "You are not authorized to tip");
        tipForBuyer += msg.value;
    }

    function payOutBuyer(address _msgSender) public {
        require(_msgSender == buyer, "You are not authorized to settle");
        if (dispute == false) {
            (bool success0, ) = seller.call{
                value: sellerCollateral.add(tipForSeller).add(costCollateral)
            }("");
            (bool success1, ) = buyer.call{
                value: buyerCollateral.add(tipForBuyer)
            }("");
            if (!success0) {
                revert Transfer__Failed();
            }
            if (!success1) {
                revert Transfer__Failed();
            }
            buyerCollateral = 0;
            sellerCollateral = 0;
            tipForBuyer = 0;
            tipForSeller = 0;
            finalSettlement = true;
            pending = false;
        } else {
            if (sellerSettled == true) {
                TxFactory(TxFactoryContractAddress).removeTx(
                    address(this),
                    seller,
                    buyer
                );
                (bool success0, ) = seller.call{
                    value: sellerCollateral.add(tipForSeller).add(
                        costCollateral
                    )
                }("");
                (bool success1, ) = buyer.call{
                    value: buyerCollateral.add(tipForBuyer)
                }("");
                if (!success0) {
                    revert();
                }
                if (!success1) {
                    revert();
                }
                finalSettlement = true;
                pending = false;
                tipForBuyer = 0;
                tipForSeller = 0;
                buyerCollateral = 0;
                sellerCollateral = 0;
            }
        }
    }

    function buyerSettle() public {
        require(msg.sender == buyer, "You are not authorized to settle");
        buyerSettled = true;
        payOutBuyer(msg.sender);
    }

    function payOutSeller(address _msgSender) public {
        require(_msgSender == seller, "You are not authorized to settle");
        if (dispute == true && buyerSettled == true) {
            (bool success0, ) = seller.call{
                value: sellerCollateral.add(tipForSeller).add(costCollateral)
            }("");
            (bool success1, ) = buyer.call{
                value: buyerCollateral.add(tipForBuyer)
            }("");
            if (!success0) {
                revert();
            }
            if (!success1) {
                revert();
            }
            finalSettlement = true;
            pending = false;
            tipForBuyer = 0;
            tipForSeller = 0;
            buyerCollateral = 0;
            sellerCollateral = 0;
        }
    }

    function sellerSettle() public {
        require(msg.sender == seller, "You are not authorized to settle");
        sellerSettled = true;
        payOutSeller(msg.sender);
    }

    function sellerRefund() public {
        require(msg.sender == seller, "You are not autherized to refund");
        (bool success0, ) = seller.call{
            value: sellerCollateral.add(tipForSeller)
        }("");
        (bool success1, ) = buyer.call{value: buyerCollateral.add(tipForBuyer).add(costCollateral)}(
            ""
        );
        if (!success0) {
            revert();
        }
        if (!success1) {
            revert();
        }
        finalSettlement = true;
        pending = false;
        tipForBuyer = 0;
        tipForSeller = 0;
        buyerCollateral = 0;
        sellerCollateral = 0;
    }

    //Getter functions

    function getSellerAddress() public view returns (address) {
        return seller;
    }

    function getBuyerAddress() public view returns (address) {
        return buyer;
    }

    function getTransactionAddress() public view returns (address) {
        return address(this);
    }

    function getSellerCollateral() public view returns (uint256) {
        return sellerCollateral;
    }

    function getBuyerCollateral() public view returns (uint256) {
        return buyerCollateral;
    }

    function getItem() public view returns (string memory) {
        return item;
    }

    function getPrice() public view returns (uint256) {
        return price;
    }

    function getSellerPhysicalAddress() public view returns (string memory) {
        return sellerPhysicalAddress;
    }

    function getBuyerPhysicalAddress() public view returns (string memory) {
        return buyerPhysicalAddress;
    }

    function getId() public view returns (uint256) {
        return id;
    }

    function getTotalContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPending() public view returns (bool) {
        return pending;
    }

    function getFinalSettlement() public view returns (bool) {
        return finalSettlement;
    }

    function getDispute() public view returns (bool) {
        return dispute;
    }

    function getTipForBuyer() public view returns (uint256) {
        return tipForBuyer;
    }

    function getTipForSeller() public view returns (uint256) {
        return tipForSeller;
    }

    function getSellerSettled() public view returns (bool) {
        return sellerSettled;
    }

    function getBuyerSettled() public view returns (bool) {
        return buyerSettled;
    }

    function getCost() public view returns (uint256) {
        return costCollateral;
    }

    function getIpfsImage() public view returns (string memory) {
        return ipfsImage;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Tx.sol";

contract TxFactory{
    address TxFactoryAddress;
    address TxContractAddress;
    uint256 id;

    mapping(address => address[]) public transactions;
    address[] public s_transactionsArray;

    event Created(address _contractAddress);

    constructor() {
        id = 0;
    }

    function createTxContract(
        string memory _item,
        uint256 _price,
        string memory _sellerPhysicalAddress,
        string memory _ipfsImage
    ) public payable {
        require(msg.value >= _price);
        id += 1;
        Tx newContract = (new Tx){value: _price}(
            _ipfsImage,
            _item,
            _price,
            _sellerPhysicalAddress,
            msg.sender,
            id,
            address(this)
        );
        emit Created(address(newContract));
    }

    function setTransaction(
        address _seller,
        address _txContractAddress
    ) public {
        transactions[_seller].push(_txContractAddress);
        s_transactionsArray.push(_txContractAddress);
    }

    function setBuyerTransaction(address _buyer, address _txContractAddress) public {
        transactions[_buyer].push(_txContractAddress);
    }

    function removeFromPublicArray(address _transactionAddress) public {
         address[] memory transactionsArray = s_transactionsArray;
        for (uint256 i = 0; i < transactionsArray.length; i++) {
            if (transactionsArray[i] == _transactionAddress) {
                s_transactionsArray[i] = transactionsArray[
                    transactionsArray.length - 1
                ];
                s_transactionsArray.pop();
            }
        }
    }

    function removeTx(
        address _transactionAddress,
        address _seller,
        address _buyer
    ) public {
        address[] memory sellerTransactions = transactions[_seller];
        for (uint256 i = 0; i < sellerTransactions.length; i++) {
            if (sellerTransactions[i] == _transactionAddress) {
                transactions[_seller][i] = sellerTransactions[
                    sellerTransactions.length - 1
                ];
                transactions[_seller].pop();
            }
        }
        address[] memory buyerTransactions = transactions[_buyer];
        for (uint256 i = 0; i < buyerTransactions.length; i++) {
            if (buyerTransactions[i] == _transactionAddress) {
                transactions[_buyer][i] = buyerTransactions[
                    buyerTransactions.length - 1
                ];
                transactions[_buyer].pop();
            }
        }
    }

    function getId() public view returns (uint256) {
        return id;
    }

    function getLengthOfTransactionArray() public view returns (uint) {
        return s_transactionsArray.length;
    }
    
    function getTransaction(
        uint256 _id
    ) public view returns (address _transactionAddress) {
        address[] memory transactionsArray = s_transactionsArray;
        for (uint256 i = 0; i < transactionsArray.length; i++) {
            if (Tx(transactionsArray[i]).getId() == _id) {
                _transactionAddress = s_transactionsArray[i];
            }
        }
    }
    function getTransactions() public view returns(address[] memory) {
        return s_transactionsArray;
    }
    function getUserAddresses(address _userAddress) public view returns(address[] memory) {
        return transactions[_userAddress];
    }
}