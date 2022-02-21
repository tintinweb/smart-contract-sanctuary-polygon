/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

//SPDX-License-Identifier: MIT
// File: contracts/libs/LibGene.sol

pragma solidity ^0.8.0;

library LibGene {
    uint256 private constant _EFF_INDEX = 0;
    uint256 private constant _CUR_INDEX = 1;
    uint256 private constant _LUK_INDEX = 2;
    uint256 private constant _VIT_INDEX = 3;
    uint256 private constant _EFF_W_INDEX = 4;
    uint256 private constant _CUR_W_INDEX = 5;
    uint256 private constant _LUK_W_INDEX = 6;
    uint256 private constant _VIT_W_INDEX = 7;
    bytes32 private constant _GENDER_MASK =
        0x0000000000000000800000000000000000000000000000000000000000000000;

    // uint256 private constant _EFFICIENCY_OFFSET = 0;
    // uint256 private constant _CURIOSITY_OFFSET = 8;
    // uint256 private constant _LUCK_OFFSET = 16;
    // uint256 private constant _VITALITY_OFFSET = 24;

    function gender(bytes32 gene) internal pure returns (bool) {
        // false: female
        // true: male
        return (gene & _GENDER_MASK) != 0;
    }

    function efficiency(bytes32 gene) internal pure returns (uint8) {
        return uint8(gene[_EFF_INDEX]);
    }

    function curiosity(bytes32 gene) internal pure returns (uint8) {
        return uint8(gene[_CUR_INDEX]);
    }

    function luck(bytes32 gene) internal pure returns (uint8) {
        return uint8(gene[_LUK_INDEX]);
    }

    function vitality(bytes32 gene) internal pure returns (uint8) {
        return uint8(gene[_VIT_INDEX]);
    }

    function wEfficiency(bytes32 gene) internal pure returns (uint8) {
        return uint8(gene[_EFF_W_INDEX]);
    }

    function wCuriosity(bytes32 gene) internal pure returns (uint8) {
        return uint8(gene[_CUR_W_INDEX]);
    }

    function wLuck(bytes32 gene) internal pure returns (uint8) {
        return uint8(gene[_LUK_W_INDEX]);
    }

    function wVitality(bytes32 gene) internal pure returns (uint8) {
        return uint8(gene[_VIT_W_INDEX]);
    }

    function genGene(
        bytes32 gene,
        bool _gender,
        uint8 _efficiency,
        uint8 _curiosity,
        uint8 _luck,
        uint8 _vitality
    ) internal pure returns (bytes32) {
        gene = gene | bytes1(_efficiency);
        gene = gene | (bytes32(bytes1(_curiosity)) >> (_CUR_INDEX * 8));
        gene = gene | (bytes32(bytes1(_luck)) >> (_LUK_INDEX * 8));
        gene = gene | (bytes32(bytes1(_vitality)) >> ((_VIT_INDEX) * 8));
        return _gender ? gene | _GENDER_MASK : gene;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
}

// File: contracts/interfaces/ICatzFood.sol

pragma solidity ^0.8.0;


interface ICatzFood is IERC20 {
    function mint(address to, uint256 amount) external;
}

// File: contracts/interfaces/ICGT.sol

pragma solidity ^0.8.0;


interface ICGT is IERC20 {
    function minters(address minter) external returns (bool);

    function addMinter(address minter) external;

    function removeMinter(address minter) external;

    function mint(address to, uint256 amount) external;
}

// File: contracts/interfaces/ICFT.sol

pragma solidity ^0.8.0;


interface ICFT is IERC20 {
    function minters(address minter) external view returns (bool);

    function addMinter(address minter) external;

    function removeMinter(address minter) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: contracts/interfaces/ICatz.sol

pragma solidity ^0.8.0;


interface ICatz is IERC721 {
    struct CatzInfo {
        // 0000000000000000 0000000000000000 0000000000000000 00 00 00 00 00 00 00 00
        bytes32 gene;
    }

    function breeders(address breeder) external view returns (bool);

    function getCatz(uint256 id)
        external
        view
        returns (bytes32 gene, uint256 birthday);

    function addBreeder(address breeder) external;

    function removeBreeder(address breeder) external;

    function isValidCatz(uint256 id) external view returns (bool);

    function catzs(uint256) external view returns (CatzInfo memory);

    function breedCatz(bytes32 gene, address to) external returns (uint256);
}

// File: contracts/Catzntrate.sol







contract Catzntrate {
    using LibGene for bytes32;

    enum State {
        Idle,
        Working,
        Waiting,
        Resting,
        Petting,
        End
    }

    struct CatzInfo {
        State state;
        CatzLevel level;
        uint256 energy;
        uint256 hunger;
        bool rewardCgt;
        CatzAttr attr;
        uint256 counterStart;
        uint256 counter;
        uint256 rewardDebt;
        uint256 lastEatTime;
        uint256 lastRefillTime;
    }

    struct CatzLevel {
        uint256 level;
        uint256 exp;
        uint256 skillPoint;
    }

    struct CatzAttr {
        uint256 eff;
        uint256 cur;
        uint256 luk;
        uint256 vit;
    }

    struct UserInfo {
        uint256 level;
        uint256 earning;
    }

    // constants
    uint256 private constant _TIME_BASE = 1645261200;
    uint256 private constant _LEVEL_MAX = 30;
    uint256 private constant _EXP_BASE = 50;
    uint256 private constant _EXP_UP = 10;
    uint256 private constant _EXP_PER_MIN = 2;
    uint256 private constant _SKILL_POINTS_UP = 4;
    uint256 private constant _HUNGER_LIMIT = 100;
    uint256 private constant _EAT_SPEED_BASE = 100;
    uint256 private constant _EARN_LIMIT_BASE = 50;
    uint256 private constant _EARN_LEVEL = 3;
    uint256 private constant _EARN_LIMIT_UP = 10;
    uint256 private constant _EARN_K = 40000000000000;
    uint256 private constant _ENERGY_MAX = 50;
    uint256 private constant _NORMAL_EAT_TIME = 40 * 60;
    uint256 private constant _WORK_EAT_TIME = 5 * 60;
    uint256 private constant _ENERGY_COST_TIME = 60;
    uint256 private constant _ENERGY_REFILL_TIME = 24 * 60 * 60;
    uint256 private constant _COST_BASE = 3 ether;
    uint256 private constant _COST_UP = 0.1 ether;

    // storage
    mapping(uint256 => CatzInfo) public catzInfos;
    mapping(address => UserInfo) public userInfos;
    ICatz public catz;
    ICFT public cft;
    ICGT public cgt;
    ICatzFood public cf;
    uint256 public workTime;
    uint256 public restTime;
    uint256 public effMultiplier;
    uint256 public curMultiplier;
    uint256 public lukMultiplier;
    uint256 public vitMultiplier;
    uint256 public rewardCftMultiplier;
    uint256 public rewardCgtMultiplier;
    uint256 public speedUp;

    // event
    event WorkStarted(uint256 id, uint256 timestamp);
    event WorkPaused(uint256 id, uint256 timestamp);
    event WorkStopped(uint256 id, uint256 timestamp);
    event Resting(uint256 id, uint256 timestamp);
    event Petting(uint256 id, uint256 timestamp);
    event Feeded(uint256 id, uint256 timestamp);

    // error
    error InvalidState(State current);
    error InvalidOwner(address current);
    error InvalidCatz(uint256 id);

    modifier whenState(uint256 id, State expected) {
        State current = catzInfos[id].state;
        if (current != expected) {
            revert InvalidState(current);
        }
        _;
    }

    modifier whenStates(
        uint256 id,
        State expected1,
        State expected2
    ) {
        State current = catzInfos[id].state;
        if (current != expected1 && current != expected2) {
            revert InvalidState(current);
        }
        _;
    }

    modifier whenNotState(uint256 id, State unexpected) {
        State current = catzInfos[id].state;
        if (current == unexpected) {
            revert InvalidState(current);
        }
        _;
    }

    modifier isValidCatz(uint256 id) {
        if (!catz.isValidCatz(id)) {
            revert InvalidCatz(id);
        }
        _;
    }

    modifier isOwner(uint256 id) {
        address owner = catz.ownerOf(id);
        if (msg.sender != owner) {
            revert InvalidOwner(msg.sender);
        }
        _;
    }

    modifier updateState(uint256 id, uint256 timestamp) {
        require(timestamp <= block.timestamp, "no modifying future");
        if (catzInfos[id].lastRefillTime == 0) {
            _initialize(id, timestamp);
        }
        _refillEnergy(id, timestamp);
        _updateState(id, timestamp);
        _;
    }

    function _initialize(uint256 id, uint256 timestamp) internal {
        uint256 time = timestamp -
            ((timestamp - _TIME_BASE) % _ENERGY_REFILL_TIME);
        catzInfos[id].lastRefillTime = time;
        catzInfos[id].lastEatTime = time;
    }

    function _refillEnergy(uint256 id, uint256 timestamp) internal {
        CatzInfo storage catzInfo = catzInfos[id];
        uint256 timeInterval = timestamp - catzInfo.lastRefillTime;
        if (timeInterval > _ENERGY_REFILL_TIME) {
            catzInfo.energy = 0;
            userInfos[msg.sender].earning = 0;
            uint256 remain = timeInterval % _ENERGY_REFILL_TIME;
            catzInfo.lastRefillTime = timestamp - remain;
        }
    }

    constructor(
        ICatz catz_,
        ICFT cft_,
        ICGT cgt_,
        ICatzFood cf_
    ) {
        catz = catz_;
        cft = cft_;
        cgt = cgt_;
        cf = cf_;
        effMultiplier = 1;
        curMultiplier = 1;
        lukMultiplier = 1;
        vitMultiplier = 1;
        rewardCftMultiplier = 100;
        rewardCgtMultiplier = 1;
        workTime = 25 * 60;
        restTime = 5 * 60;
        speedUp = 1;
    }

    // Getters
    function getStats(uint256 id)
        public
        view
        returns (
            uint256 efficiency,
            uint256 curiosity,
            uint256 luck,
            uint256 vitality
        )
    {
        (bytes32 gene, ) = catz.getCatz(id);
        CatzAttr memory catzAttr = catzInfos[id].attr;
        efficiency = gene.efficiency() + catzAttr.eff * effMultiplier;
        curiosity = gene.curiosity() + catzAttr.cur * curMultiplier;
        luck = gene.luck() + catzAttr.luk * lukMultiplier;
        vitality = gene.vitality() + catzAttr.vit * vitMultiplier;
    }

    function getStates(uint256 id)
        external
        view
        returns (
            State state,
            uint256 level,
            uint256 skillPoint,
            uint256 energy,
            uint256 hunger,
            bool gender
        )
    {
        CatzInfo memory catzInfo = catzInfos[id];
        (bytes32 gene, ) = catz.getCatz(id);
        return (
            catzInfo.state,
            catzInfo.level.level,
            catzInfo.level.skillPoint,
            catzInfo.energy,
            catzInfo.hunger,
            gene.gender()
        );
    }

    function _getEatSpeed(uint256 id) internal view returns (uint256) {
        (, , , uint256 vit) = getStats(id);
        return vit + _EAT_SPEED_BASE;
    }

    function getEarnLimit(address user) public view returns (uint256) {
        uint256 level = userInfos[user].level;
        return ((level / _EARN_LEVEL) * _EARN_LIMIT_UP) + _EARN_LIMIT_BASE;
    }

    // Testing usage
    function setSpeedUp(uint256 rate) external {
        speedUp = rate;
    }

    // Actions
    function workStart(uint256 id, uint256 timestamp)
        external
        updateState(id, timestamp)
        whenState(id, State.Idle)
        isValidCatz(id)
        isOwner(id)
    {
        CatzInfo storage catzInfo = catzInfos[id];
        require(catzInfo.counterStart == 0, "Should be initial work");
        require(catzInfo.rewardDebt == 0, "Should be no reward debt");
        require(catzInfo.energy < _ENERGY_MAX, "No energy");
        require(catzInfo.hunger < _HUNGER_LIMIT, "Hungry");
        catzInfo.state = State.Working;
        catzInfo.counterStart = timestamp;
        catzInfo.counter = workTime;
    }

    function workPause(uint256 id, uint256 timestamp)
        external
        updateState(id, timestamp)
        whenState(id, State.Working)
        isValidCatz(id)
        isOwner(id)
    {
        (uint256 eff, , , ) = getStats(id);
        uint256 timePassed = timestamp - catzInfos[id].counterStart;
        CatzInfo storage catzInfo = catzInfos[id];
        catzInfo.counter -= timePassed;
        catzInfo.state = State.Waiting;
        catzInfo.rewardDebt = _calReward(
            eff,
            timePassed,
            catzInfo.rewardCgt ? rewardCgtMultiplier : rewardCftMultiplier
        );
    }

    function workUnpause(uint256 id, uint256 timestamp)
        external
        updateState(id, timestamp)
        whenState(id, State.Waiting)
        isValidCatz(id)
        isOwner(id)
    {
        CatzInfo storage catzInfo = catzInfos[id];
        catzInfo.state = State.Working;
        catzInfo.counterStart = timestamp;
    }

    function workStop(
        uint256 id,
        uint256 timestamp,
        bool isAdventure
    )
        external
        updateState(id, timestamp)
        whenStates(id, State.Working, State.Waiting)
        isValidCatz(id)
        isOwner(id)
    {
        CatzInfo storage catzInfo = catzInfos[id];
        if (catzInfo.state == State.Resting) {
            _pet(id, isAdventure);
        }
        catzInfo.state = State.Idle;
        catzInfo.counterStart = 0;
        catzInfo.counter = 0;
        catzInfo.rewardDebt = 0;
    }

    function pet(
        uint256 id,
        uint256 timestamp,
        bool isAdventure
    )
        external
        updateState(id, timestamp)
        whenState(id, State.Resting)
        isValidCatz(id)
        isOwner(id)
    {
        _pet(id, isAdventure);
    }

    function _pet(uint256 id, bool isAdventure) internal {
        CatzInfo storage catzInfo = catzInfos[id];
        catzInfo.state = State.Petting;
        uint256 reward = catzInfo.rewardDebt;
        uint256 left = getEarnLimit(msg.sender) - userInfos[msg.sender].earning;
        reward = reward < left ? reward : left;

        catzInfo.rewardDebt = 0;
        // Send reward
        if (catzInfo.rewardCgt) {
            cgt.mint(msg.sender, reward);
        } else {
            cft.mint(msg.sender, reward);
        }

        if (isAdventure) {
            // give user 1 cat food as reward
            cf.mint(msg.sender, 1 ether);
        }
    }

    function feed(
        uint256 id,
        uint256 timestamp,
        uint256 amount
    )
        external
        updateState(id, timestamp)
        whenNotState(id, State.Working)
        isValidCatz(id)
        isOwner(id)
    {
        CatzInfo storage catzInfo = catzInfos[id];
        // uint256 limit = getHungerLimit(id);
        uint256 point = ((amount / 1 ether)) * 10;
        require(catzInfo.hunger - point >= 0, "over hunger limit");
        cf.transferFrom(msg.sender, address(this), amount);
        // token convert to point
        // 1 food recover 10 point of hunger
        catzInfo.hunger -= point;
    }

    // Stats actions
    function levelUp(uint256 id, uint256 timestamp)
        external
        updateState(id, timestamp)
        whenNotState(id, State.Working)
        isValidCatz(id)
        isOwner(id)
    {
        CatzLevel storage catzLevel = catzInfos[id].level;
        require(catzLevel.exp == _getLevelExp(id), "exp insufficient");
        uint256 level = catzLevel.level;
        if (level < _LEVEL_MAX) {
            catzLevel.level++;
            catzLevel.exp = 0;
            catzLevel.skillPoint += _SKILL_POINTS_UP;
            // Level up user
            userInfos[msg.sender].level++;
            cft.burn(msg.sender, _getLevelUpCost(level));
        }
    }

    function _getLevelUpCost(uint256 level) internal pure returns (uint256) {
        return _COST_BASE + _COST_UP * level;
    }

    function addStats(
        uint256 id,
        uint256 timestamp,
        CatzAttr calldata attr
    )
        external
        updateState(id, timestamp)
        whenNotState(id, State.Working)
        isValidCatz(id)
        isOwner(id)
    {
        CatzInfo storage catzInfo = catzInfos[id];
        {
            uint256 sum = attr.eff + attr.cur + attr.luk + attr.vit;
            catzInfo.level.skillPoint -= sum;
        }
        catzInfo.attr.eff += attr.eff;
        catzInfo.attr.cur += attr.cur;
        catzInfo.attr.luk += attr.luk;
        catzInfo.attr.vit += attr.vit;
    }

    function setRewardCgt(
        uint256 id,
        uint256 timestamp,
        bool flag
    )
        external
        updateState(id, timestamp)
        whenState(id, State.Idle)
        isValidCatz(id)
        isOwner(id)
    {
        CatzInfo storage catzInfo = catzInfos[id];
        if (flag) {
            require(catzInfo.level.level == 29, "Level too low");
        }
        catzInfo.rewardCgt = flag;
    }

    function poke(uint256 id) external updateState(id, block.timestamp) {
        return;
    }

    // Internals
    function _updateState(uint256 id, uint256 timestamp) internal {
        CatzInfo storage catzInfo = catzInfos[id];
        if (catzInfo.state == State.Idle) {
            _dine(id, timestamp, _NORMAL_EAT_TIME);
        } else if (catzInfo.state == State.Working) {
            // Verify going to Resting or not
            uint256 timeInterval = timestamp - catzInfo.counterStart;
            if (timeInterval > catzInfo.counter) {
                (uint256 efficiency, , , ) = getStats(id);
                uint256 energizedTime = (_ENERGY_MAX - catzInfo.energy) *
                    _ENERGY_COST_TIME;
                uint256 workingTime = energizedTime > catzInfo.counter
                    ? catzInfo.counter
                    : energizedTime;
                workingTime = _dine(
                    id,
                    catzInfo.counterStart + workingTime,
                    _WORK_EAT_TIME
                );
                catzInfo.energy += workingTime / _ENERGY_COST_TIME;
                {
                    uint256 exp = (workingTime * _EXP_PER_MIN) / 60;
                    uint256 toLimit = _getLevelExp(id) - catzInfo.level.exp;
                    exp = exp < toLimit ? exp : toLimit;
                    catzInfo.level.exp += exp;
                }

                catzInfo.rewardDebt = _calReward(
                    efficiency,
                    workingTime,
                    catzInfo.rewardCgt
                        ? rewardCgtMultiplier
                        : rewardCftMultiplier
                );
                catzInfo.counterStart += catzInfo.counter;
                catzInfo.counter = restTime;
                catzInfo.state = State.Resting;
            } else {
                uint256 energizedTime = (_ENERGY_MAX - catzInfo.energy) *
                    _ENERGY_COST_TIME;
                uint256 workingTime = energizedTime > timeInterval
                    ? timeInterval
                    : energizedTime;
                workingTime = _dine(
                    id,
                    catzInfo.counterStart + workingTime,
                    _WORK_EAT_TIME
                );
                catzInfo.energy += workingTime / _ENERGY_COST_TIME;
                {
                    uint256 exp = (workingTime * _EXP_PER_MIN) / 60;
                    uint256 toLimit = _getLevelExp(id) - catzInfo.level.exp;
                    exp = exp < toLimit ? exp : toLimit;
                    catzInfo.level.exp += exp;
                }
            }
        } else if (catzInfo.state == State.Waiting) {
            _dine(id, timestamp, _NORMAL_EAT_TIME);
        } else if (catzInfo.state == State.Resting) {
            _dine(id, timestamp, _NORMAL_EAT_TIME);
        } else if (catzInfo.state == State.Petting) {
            _dine(id, timestamp, _NORMAL_EAT_TIME);
            // Verify going to Working or not
            uint256 timeInterval = timestamp - catzInfo.counterStart;
            if (timeInterval > catzInfo.counter) {
                _dine(
                    id,
                    catzInfo.counterStart + catzInfo.counter,
                    _NORMAL_EAT_TIME
                );
                catzInfo.counterStart += catzInfo.counter;
                catzInfo.counter = workTime;
                catzInfo.state = State.Working;
            } else {
                _dine(id, timestamp, _NORMAL_EAT_TIME);
            }
        } else {
            revert("Invalid state");
        }
    }

    function _getLevelExp(uint256 id) internal view returns (uint256) {
        uint256 level = catzInfos[id].level.level;
        return _EXP_BASE + (level * _EXP_UP);
    }

    function _dine(
        uint256 id,
        uint256 timestamp,
        uint256 eatSpeed
    ) internal returns (uint256 eatTime) {
        uint256 finalSpeed = (eatSpeed * _getEatSpeed(id)) /
            _EAT_SPEED_BASE /
            speedUp;
        CatzInfo storage catzInfo = catzInfos[id];
        eatTime = timestamp - catzInfo.lastEatTime;
        uint256 eat = eatTime / finalSpeed;
        uint256 food = _HUNGER_LIMIT - catzInfo.hunger;
        if (food > eat) {
            catzInfo.hunger += eat;
        } else {
            catzInfo.hunger = _HUNGER_LIMIT;
            eatTime = food * finalSpeed;
        }
        catzInfo.lastEatTime = timestamp;
    }

    function _calReward(
        uint256 eff,
        uint256 time,
        uint256 multiplier
    ) internal pure returns (uint256) {
        return eff * time * multiplier * _EARN_K;
    }
}