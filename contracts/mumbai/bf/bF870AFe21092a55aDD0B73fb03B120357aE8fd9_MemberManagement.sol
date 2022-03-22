import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8;

contract MemberManagement is ReentrancyGuard {
    using SafeMath for uint256;
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can access this function");
        _;
    }

    constructor(address _owner) {
        // protocolFeeIndependentNetwork = 10;
        memberCount = 0;
        networkCount = 0;
        owner = _owner;
        // addNewNetwork(30); //3% commisions
        // applyToBeAMember(true);
        // registerMember(1);
        // addSingleMemberToNetwork(1, 1);
    }

    struct Member {
        uint256 Member_id;
        address public_address;
        bool isMarketplace; //true for marketplace and false for shop
        bool active;
        bool independent;
        uint256 independentCommission;
        uint256 independentProtocolCommission;
    }

    struct Network {
        uint256 network_id;
        bool active;
        //uint256 totalCommisions;
        uint256 listerCommission;
        uint256 sellerCommission;
        uint256 protocolCommission;
    }

    address private escrowAddress;
    address public owner;
    uint256 public memberCount;
    uint256 public networkCount;
    uint256 private lowerCappingCommisions = 0; //0%
    uint256 private upperCappingCommisions = 100; //10%
    // Member_id to Member
    mapping(uint256 => Member) public Member_directory;
    // network_id to network
    mapping(uint256 => Network) public network_directory;

    event NetworkAdded(uint256 indexed network_id);
    event NetworkDeleted(uint256 indexed network_id);
    event NetworkListerCommissionChanged(
        uint256 indexed network_id,
        uint256 new_commission
    );
    event NetworkSellerCommissionChanged(
        uint256 indexed network_id,
        uint256 new_commission
    );
    event NetworkProtocolCommissionChanged(
        uint256 indexed network_id,
        uint256 new_commission
    );
    event MemberApplied(uint256 indexed apply_id, bool indexed is_Marketplace);
    event MemberRegistered(
        uint256 indexed member_id,
        uint256 indexed apply_id,
        bool indexed is_Marketplace
    );
    event MemberDeactivated(
        uint256 indexed member_id,
        bool indexed is_Marketplace
    );
    event MemberAddressChanged(uint256 indexed member_id, address newAddress);
    event MemberAddedToNetwork(
        uint256 indexed member_id,
        uint256 indexed network_id
    );
    event MemberRemovedFromNetwork(
        uint256 indexed member_id,
        uint256 indexed network_id
    );
    event MemberAddedShopCreator(
        uint256 indexed member_id,
        address indexed creator
    );
    event MemberRemovedShopCreator(
        uint256 indexed member_id,
        address indexed creator
    );

    //the commisions will be distributed 1/3 for all involved parties (i.e., listMarketplace, soldMarketplace and protocol)
    function addNewNetwork(
        uint256 _listerC,
        uint256 _sellerC,
        uint256 _protocolC
    ) public onlyOwner {
        require(
            _listerC >= lowerCappingCommisions &&
                _listerC <= upperCappingCommisions,
            "lister commision capping conditions not satisfied"
        );
        require(
            _sellerC >= lowerCappingCommisions &&
                _sellerC <= upperCappingCommisions,
            "Seller commision capping conditions not satisfied"
        );
        require(
            _protocolC >= lowerCappingCommisions &&
                _protocolC <= upperCappingCommisions,
            "Protocol commission capping conditions not satisfied"
        );
        // require(
        //     _totalCommisions % 3 == 0,
        //     "Commision percentage should be a multiple of 3"
        // );
        networkCount = networkCount.add(1);
        network_directory[networkCount] = Network(
            networkCount,
            true,
            _listerC,
            _sellerC,
            _protocolC
        );
        emit NetworkAdded(networkCount);
    }

    // bool[][] public networkMember; //memberCount * networkCount
    mapping(uint256 => mapping(uint256 => bool)) public networkMember; //memberCount * networkCount

    //deleting any network will make its column false
    function deleteNetwork(uint256 _network_id) public onlyOwner {
        require(
            _network_id > 0 && _network_id <= networkCount,
            "invalid network id provided!!!"
        );
        require(_network_id != 1, "cannot delete network 1!!!");
        network_directory[_network_id].active = false;
        uint256 rows;
        uint256 cols;
        for (rows = 1; rows <= memberCount; rows++) {
            for (cols = 1; cols <= networkCount; cols++)
                if (cols == _network_id) networkMember[rows][cols] = false;
        }
        emit NetworkDeleted(_network_id);
    }

    //change network commission
    function changeNetworkListerCommission(
        uint256 network_id,
        uint256 new_percent
    ) public onlyOwner {
        require(
            network_id > 0 && network_id <= networkCount,
            "Invalid network ID!!!"
        );
        require(
            new_percent >= lowerCappingCommisions &&
                new_percent <= upperCappingCommisions,
            "Percentage out of bounds!!"
        );
        // require(
        //     new_percent % 3 == 0,
        //     "Commision percentage should be a multiple of 3"
        // );
        network_directory[network_id].listerCommission = new_percent;
        emit NetworkListerCommissionChanged(network_id, new_percent);
    }

    function changeNetworkSellerCommission(
        uint256 network_id,
        uint256 new_percent
    ) public onlyOwner {
        require(
            network_id > 0 && network_id <= networkCount,
            "Invalid network ID!!!"
        );
        require(
            new_percent >= lowerCappingCommisions &&
                new_percent <= upperCappingCommisions,
            "Percentage out of bounds!!"
        );
        // require(
        //     new_percent % 3 == 0,
        //     "Commision percentage should be a multiple of 3"
        // );
        network_directory[network_id].sellerCommission = new_percent;
        emit NetworkSellerCommissionChanged(network_id, new_percent);
    }

    function changeNetworkProtocolCommission(
        uint256 network_id,
        uint256 new_percent
    ) public onlyOwner {
        require(
            network_id > 0 && network_id <= networkCount,
            "Invalid network ID!!!"
        );
        require(
            new_percent >= lowerCappingCommisions &&
                new_percent <= upperCappingCommisions,
            "Percentage out of bounds!!"
        );
        // require(
        //     new_percent % 3 == 0,
        //     "Commision percentage should be a multiple of 3"
        // );
        network_directory[network_id].protocolCommission = new_percent;
        emit NetworkProtocolCommissionChanged(network_id, new_percent);
    }

    // Member's public address to applied status for member registration
    mapping(address => bool) public appliedRegistration;

    uint256 public applyCount;

    struct appliedMember {
        uint256 apply_id;
        bool isMarketplace;
        address public_address;
        bool publisherRegistered;
    }
    //applied to be a member
    mapping(uint256 => appliedMember) public applied_directory;

    //apply to be a Member
    function applyToBeAMember(bool _isMarketplace) public {
        require(
            appliedRegistration[msg.sender] == false,
            "Address already applied"
        );
        applyCount = applyCount.add(1);
        applied_directory[applyCount] = appliedMember(
            applyCount,
            _isMarketplace,
            msg.sender,
            false
        );
        appliedRegistration[msg.sender] = true;
        emit MemberApplied(applyCount, _isMarketplace);
    }

    //register the Member
    function registerMember(uint256 _apply_id) public onlyOwner {
        require(
            _apply_id > 0 && _apply_id <= applyCount,
            "Apply ID not present"
        );
        require(
            appliedRegistration[applied_directory[_apply_id].public_address] ==
                true,
            "Not applied yet!!!"
        );
        require(
            applied_directory[_apply_id].publisherRegistered == false,
            "Already registered!!!"
        );
        memberCount = memberCount.add(1);
        Member_directory[memberCount] = Member(
            memberCount,
            applied_directory[_apply_id].public_address,
            applied_directory[_apply_id].isMarketplace,
            true,
            true,
            100, //10%
            100 //10%
        );
        applied_directory[_apply_id].publisherRegistered = true;
        if (applied_directory[_apply_id].isMarketplace == false)
            shopMintableAddresses[memberCount].push(
                applied_directory[_apply_id].public_address
            );
        emit MemberRegistered(
            memberCount,
            _apply_id,
            Member_directory[memberCount].isMarketplace
        );
    }

    //deactivate member
    function deactivateMember(uint256 p_id) public onlyOwner {
        require(
            Member_directory[p_id].Member_id == p_id,
            "Publisher ID not present"
        );
        require(
            Member_directory[p_id].active == true,
            "Publisher already inactive!!!"
        );
        Member_directory[p_id].active = false;
        appliedRegistration[Member_directory[p_id].public_address] = false;
        uint256 cols;
        for (cols = 1; cols <= networkCount; cols++) {
            if (networkMember[p_id][cols] == true)
                networkMember[p_id][cols] = false;
        }
        emit MemberDeactivated(p_id, Member_directory[p_id].isMarketplace);
    }

    //remove member from network
    function removeMemberFromNetwork(uint256 _network_id, uint256 member_id)
        public
        onlyOwner
    {
        require(
            _network_id > 0 && _network_id <= networkCount,
            "Invalid network id provided!!!"
        );
        require(
            member_id > 0 && member_id <= memberCount,
            "Invalid publisher id provided!!!"
        );
        require(
            networkMember[member_id][_network_id] == true,
            "Member not part of network!!!"
        );
        networkMember[member_id][_network_id] = false;
        updateIndependent(member_id);
        emit MemberRemovedFromNetwork(member_id, _network_id);
    }

    //add one member to network
    function addSingleMemberToNetwork(uint256 _network_id, uint256 member_id)
        public
        onlyOwner
    {
        require(network_directory[_network_id].active, "Network inactive!!!");
        require(Member_directory[member_id].active, "Member inactive!!!");
        require(
            _network_id > 0 && _network_id <= networkCount,
            "Invalid network id provided!!!"
        );
        require(
            member_id > 0 && member_id <= memberCount,
            "Invalid publisher id provided!!!"
        );
        require(
            networkMember[member_id][_network_id] == false,
            "Member already part of network!!!"
        );
        // if (_network_id != 1)
        //     require(
        //         !checkPrivateNetworkJoined(member_id),
        //         "Member already part of a private network"
        //     );
        if (Member_directory[member_id].independent)
            Member_directory[member_id].independent = false;
        networkMember[member_id][_network_id] = true;
        emit MemberAddedToNetwork(member_id, _network_id);
    }

    //check netwotrk commission
    function getNetworkCommissions(uint256 network_id)
        external
        view
        returns (
            uint256 lister,
            uint256 seller,
            uint256 protocol
        )
    {
        return (
            network_directory[network_id].listerCommission,
            network_directory[network_id].sellerCommission,
            network_directory[network_id].protocolCommission
        );
    }

    //check if member part of network
    function checkMember(uint256 network_id, uint256 member_id)
        external
        view
        returns (bool)
    {
        return (networkMember[member_id][network_id]);
    }

    // function checkPrivateNetworkJoined(uint256 member_id)
    //     public
    //     view
    //     returns (bool)
    // {
    //     require(Member_directory[member_id].active, "Member is inactive");
    //     for (uint256 i = 2; i <= networkCount; i++)
    //         if (networkMember[member_id][i] == true) return true;
    //     return false;
    // }

    function checkNetworkStatus(uint256 network_id)
        external
        view
        returns (bool)
    {
        return (network_directory[network_id].active);
    }

    function checkMemberStatus(uint256 member_id) external view returns (bool) {
        return (Member_directory[member_id].active);
    }

    //shop id to address array
    mapping(uint256 => address[]) shopMintableAddresses;

    //check if the minter is allowed to mint
    function canMint(uint256 member_id, address _addr)
        public
        view
        returns (bool)
    {
        require(
            Member_directory[member_id].active == true,
            "Marketplace/Shop is not active"
        );
        if (Member_directory[member_id].isMarketplace == true) return true;
        else {
            address[] memory mintable = getMintableAddresses(member_id);
            for (uint256 i = 0; i < mintable.length; i++) {
                if (mintable[i] == _addr) return true;
            }
            return false;
        }
    }

    function getMintableAddresses(uint256 member_id)
        public
        view
        returns (address[] memory)
    {
        require(
            Member_directory[member_id].isMarketplace == false,
            "Only shops can access this function"
        );
        return (shopMintableAddresses[member_id]);
    }

    function giveMintPermission(uint256 member_id, address _addr) public {
        require(
            Member_directory[member_id].public_address == msg.sender,
            "Only the publisher have access to this function"
        );
        require(
            Member_directory[member_id].isMarketplace == false,
            "Only shops can access this function"
        );
        require(!canMint(member_id, _addr), "Address can already mint");
        shopMintableAddresses[member_id].push(_addr);
        emit MemberAddedShopCreator(member_id, _addr);
    }

    function revokeMintPermission(uint256 member_id, address _addr) public {
        require(
            Member_directory[member_id].public_address == msg.sender,
            "Only the publisher have access to this function"
        );
        require(
            _addr != Member_directory[member_id].public_address,
            "Cannot revoke mint permission of the shop owner!!!"
        );
        require(
            Member_directory[member_id].isMarketplace == false,
            "Only shops can access this function"
        );
        require(canMint(member_id, _addr), "Address already not allowed");
        for (uint256 i = 0; i < shopMintableAddresses[member_id].length; i++) {
            if (shopMintableAddresses[member_id][i] == _addr) {
                for (; i < shopMintableAddresses[member_id].length - 1; i++) {
                    shopMintableAddresses[member_id][i] = shopMintableAddresses[
                        member_id
                    ][i + 1];
                }
                shopMintableAddresses[member_id].pop();
            }
        }
        emit MemberRemovedShopCreator(member_id, _addr);
    }

    //checks if a token on sale is tradable among two platforms
    function tokenTradableAmongPublishers(
        uint256 _listedPublisherID,
        uint256 _soldPublisherID
    ) public view returns (bool) {
        require(
            _listedPublisherID > 0 && _listedPublisherID <= memberCount,
            "Invalid _listedPublisherID provided!!!"
        );
        require(
            _soldPublisherID > 0 && _soldPublisherID <= memberCount,
            "Invalid _soldPublisherID provided!!!"
        );
        if (_listedPublisherID == _soldPublisherID) return true;
        for (uint256 j = 1; j <= networkCount; j++) {
            if (
                networkMember[_listedPublisherID][j] == true &&
                networkMember[_soldPublisherID][j] == true
            ) return true;
        }
        return false;
    }

    function updateIndependent(uint256 _memberID) public {
        for (uint256 i = 1; i <= networkCount; i++) {
            if (networkMember[_memberID][i] == true) {
                //return false;
                Member_directory[_memberID].independent = false;
                break;
            }
        }
        Member_directory[_memberID].independent = true;
    }

    // uint256 public protocolFeeIndependentNetwork;

    //To calculate percentages
    function calculatePercent(uint256 value, uint256 percent)
        internal
        pure
        returns (uint256)
    {
        return (value.mul(percent)).div(1000);
    }

    //gives the commission to be applied on a particular order
    // function getTotalCommission(
    //     uint256 _listedPublisherID,
    //     uint256 _soldPublisherID
    // ) internal view returns (uint256) {
    //     for (uint256 j = 1; j <= networkCount; j++) {
    //         if (
    //             networkMember[_listedPublisherID][j] == true &&
    //             networkMember[_soldPublisherID][j] == true
    //         ) return network_directory[j].totalCommisions;
    //     }
    //     return 0;
    // }

    //takes publisher id's and return the commission percentages for listMarketplace, soldMarketplace and protocol fee;
    function getCommissionDistribution(
        uint256 _listedPublisherID,
        uint256 _soldPublisherID,
        uint256 cost
    )
        public
        view
        returns (
            uint256 listerCommission,
            uint256 sellerCommission,
            uint256 protocolCommission
        )
    {
        if (_listedPublisherID == _soldPublisherID)
            return (
                0,
                calculatePercent(
                    cost,
                    Member_directory[_listedPublisherID].independentCommission
                ),
                calculatePercent(
                    cost,
                    Member_directory[_listedPublisherID]
                        .independentProtocolCommission
                )
            );
        else {
            uint256 network = getCommonNetwork(
                _listedPublisherID,
                _soldPublisherID
            );
            require(network != 0, "Invalid trade!!!");
            return (
                calculatePercent(
                    cost,
                    network_directory[network].listerCommission
                ),
                calculatePercent(
                    cost,
                    network_directory[network].sellerCommission
                ),
                calculatePercent(
                    cost,
                    network_directory[network].protocolCommission
                )
            );
        }
        // uint256 totalCommisions = getTotalCommission(
        //     _listedPublisherID,
        //     _soldPublisherID
        // );
        // uint256 commission = calculatePercent(cost, totalCommisions.div(3));
        // return (commission, commission);
    }

    function changeIndependentProtocolFee(uint256 _memberid, uint256 newFee)
        public
        onlyOwner
    {
        require(
            newFee >= lowerCappingCommisions &&
                newFee <= upperCappingCommisions,
            "New commission out of bounds!!!"
        );
        Member_directory[_memberid].independentProtocolCommission = newFee;
    }

    function changeIndependentMemberFee(uint256 _memberid, uint256 newFee)
        public
    {
        require(
            newFee >= lowerCappingCommisions &&
                newFee <= upperCappingCommisions,
            "New commission out of bounds!!!"
        );
        require(
            msg.sender == Member_directory[_memberid].public_address ||
                msg.sender == owner,
            "Not authorized to change the fee!"
        );
        Member_directory[_memberid].independentCommission = newFee;
    }

    function getPublisherStatus(uint256 _memberID)
        external
        view
        returns (bool)
    {
        return Member_directory[_memberID].active;
    }

    function getAddress(uint256 _memberID) public view returns (address) {
        return Member_directory[_memberID].public_address;
    }

    function isMarketplace(uint256 _memberID) external view returns (bool) {
        return Member_directory[_memberID].isMarketplace;
    }

    function getCommonNetwork(uint256 _lister, uint256 _seller)
        public
        view
        returns (uint256)
    {
        for (uint256 j = 1; j <= networkCount; j++)
            if (
                networkMember[_lister][j] == true &&
                networkMember[_seller][j] == true
            ) return j;
        return 0;
    }

    function changeOwner(address _new) public onlyOwner {
        require(_new != address(0), "new owner address cannot be null");
        owner = _new;
    }

    function changeMemberAddress(address _new, uint256 _memberid) public {
        require(
            msg.sender == getAddress(_memberid) || msg.sender == owner,
            "Only member can change their own address"
        );
        Member_directory[_memberid].public_address = _new;
    }

    function changeLowerCapping(uint256 _new) public onlyOwner {
        lowerCappingCommisions = _new;
    }

    function changeUpperCapping(uint256 _new) public onlyOwner {
        upperCappingCommisions = _new;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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