/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

pragma solidity >=0.4.23 <0.6.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract MetaForceDai {
    IERC20 tokencontract = IERC20(0x12aC40582e8f35fd711e418e3fcDc4C338528698);
    IERC20 distributetoken = IERC20(0x5C74908398Ea3845165Dcb0CD235243B2b078388);
    struct User {
        uint256 id;
        address referrer;
        uint256 partnersCount;
        uint256 MaxLevel;
        uint256 Income;
        mapping(uint8 => bool) activeLevels;
        mapping(uint8 => O6) Matrix;
        bool autoupgrade;
    }

    struct O6 {
        address currentReferrer;
        address[] referrals;
        address[] secondLevelReferrals;
        bool blocked;
        uint256 reinvestCount;
        address closedPart;
    }

    uint8 public constant LAST_LEVEL = 12;

    uint256 totaldistributionallowed = 10000000 * 10**18;
    uint256 totaldistributed = 0;
    uint256 public productfund;
    mapping(address => User) public users;
    mapping(uint256 => address) public idToAddress;
    mapping(uint256 => address) public userIds;
    mapping(address => uint256) public balances;

    uint256 public lastUserId = 2;
    uint256 public totalearnedDai = 0 ether;
    address payable public owner;

    mapping(uint8 => uint256) public levelPrice;

    event Registration(
        address indexed user,
        address indexed referrer,
        uint256 indexed userId,
        uint256 referrerId,
        uint256 time
    );
    event Reinvest(
        address indexed user,
        address indexed currentReferrer,
        address indexed caller,
        uint8 matrix,
        uint8 level,
        uint256 time
    );
    event Upgrade(
        address indexed user,
        address indexed referrer,
        uint8 matrix,
        uint8 level,
        uint256 time
    );
    event NewUserPlace(
        address indexed user,
        uint256 indexed userId,
        address indexed referrer,
        uint256 referrerId,
        uint8 matrix,
        uint8 level,
        uint8 place,
        uint256 time,
        uint8 partnerType
    );
    event MissedDaiReceive(
        address indexed receiver,
        uint256 receiverId,
        address indexed from,
        uint256 indexed fromId,
        uint8 matrix,
        uint8 level,
        uint256 time,
        uint256 missedtype
    );
    event SentDividends(
        address indexed from,
        uint256 indexed fromId,
        address indexed receiver,
        uint256 receiverId,
        uint8 level,
        uint256 time
    );

    constructor(address payable ownerAddress) public {
        levelPrice[1] = 10 ether;
        for (uint8 i = 2; i <= LAST_LEVEL; i++) {
            levelPrice[i] = levelPrice[i - 1] * 2;
        }

        owner = ownerAddress;

        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint256(0),
            MaxLevel: uint256(0),
            Income: uint8(0),
            autoupgrade: true
        });

        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;

        for (uint8 i = 1; i <= LAST_LEVEL; i++) {
            users[ownerAddress].activeLevels[i] = true;
        }
        users[ownerAddress].MaxLevel = 12;
        userIds[1] = ownerAddress;
    }

    function() external payable {
        if (msg.data.length == 0) {
            return registration(msg.sender, owner);
        }

        registration(msg.sender, bytesToAddress(msg.data));
    }

    function registrationExt(address referrerAddress) external payable {
        registration(msg.sender, referrerAddress);
    }

    function buyNewLevel(uint8 level) external payable {
        require(
            isUserExists(msg.sender),
            "user is not exists. Register first."
        );
        require(
            tokencontract.allowance(msg.sender, address(this)) >=
                levelPrice[level],
            "invalid price"
        );
        require(level > 1 && level <= LAST_LEVEL, "invalid level");
        uint256 matrix = level == 3 || level == 6 || level == 9 || level == 12
            ? 1
            : 2;
        if (matrix == 1) {
            require(
                !users[msg.sender].activeLevels[level],
                "level already activated"
            );
            require(
                users[msg.sender].activeLevels[level - 1],
                "previous level should be activated"
            );
            address freeO3Referrer = findFreeReferrer(msg.sender, level);
            if (freeO3Referrer != users[msg.sender].referrer) {
                emit MissedDaiReceive(
                    users[msg.sender].referrer,
                    users[users[msg.sender].referrer].id,
                    msg.sender,
                    users[msg.sender].id,
                    1,
                    level,
                    block.timestamp,
                    1
                );
            }
            users[msg.sender].MaxLevel = level;
            users[msg.sender].Matrix[level].currentReferrer = freeO3Referrer;
            users[msg.sender].activeLevels[level] = true;
            updateO3Referrer(msg.sender, freeO3Referrer, level);
            totalearnedDai = totalearnedDai + levelPrice[level];
            emit Upgrade(msg.sender, freeO3Referrer, 1, level, block.timestamp);
        } else {
            require(
                !users[msg.sender].activeLevels[level],
                "level already activated"
            );
            require(
                users[msg.sender].activeLevels[level - 1],
                "previous level should be activated"
            );

            if (users[msg.sender].Matrix[level - 1].blocked) {
                users[msg.sender].Matrix[level - 1].blocked = false;
            }

            address freeO6Referrer = findFreeReferrer(msg.sender, level);
            if (freeO6Referrer != users[msg.sender].referrer) {
                emit MissedDaiReceive(
                    users[msg.sender].referrer,
                    users[users[msg.sender].referrer].id,
                    msg.sender,
                    users[msg.sender].id,
                    2,
                    level,
                    block.timestamp,
                    1
                );
            }
            users[msg.sender].MaxLevel = level;
            users[msg.sender].activeLevels[level] = true;
            updateO6Referrer(msg.sender, freeO6Referrer, level);

            totalearnedDai = totalearnedDai + levelPrice[level];
            emit Upgrade(msg.sender, freeO6Referrer, 2, level, block.timestamp);
        }
        if (totaldistributed + levelPrice[level] <= totaldistributionallowed) {
            distributetoken.transfer(msg.sender, levelPrice[level]);
            totaldistributed += levelPrice[level];
        }
        // uint256 feeamount = msg.value * adminFee / 100;
        // owner.transfer(feeamount);
    }

    function registration(address userAddress, address referrerAddress)
        private
    {
        require(
            tokencontract.allowance(userAddress, address(this)) >=
                levelPrice[1],
            "registration cost 10"
        );
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");

        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        require(size == 0, "cannot be a contract");

        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            partnersCount: 0,
            MaxLevel: 1,
            Income: 0 ether,
            autoupgrade: true
        });
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        users[userAddress].referrer = referrerAddress;
        users[userAddress].activeLevels[1] = true;
        userIds[lastUserId] = userAddress;
        lastUserId++;
        totalearnedDai = totalearnedDai + 10 ether;
        users[referrerAddress].partnersCount++;
        // address freeO3Referrer = findFreeReferrer(userAddress, 1);
        // users[userAddress].Matrix[1].currentReferrer = freeO3Referrer;
        // updateO3Referrer(userAddress, freeO3Referrer, 1);
        updateO6Referrer(userAddress, findFreeReferrer(userAddress, 1), 1);
        if (totaldistributed + levelPrice[1] <= totaldistributionallowed) {
            distributetoken.transfer(userAddress, levelPrice[1]);
            totaldistributed += levelPrice[1];
        }
        emit Registration(
            userAddress,
            referrerAddress,
            users[userAddress].id,
            users[referrerAddress].id,
            block.timestamp
        );
        // uint256 feeamount = msg.value * adminFee / 100;
        // owner.transfer(feeamount);
    }

    function updateO3Referrer(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        users[referrerAddress].Matrix[level].referrals.push(userAddress);
        uint8 partnerType;
        User memory _userdetail = users[userAddress];
        User memory _referrerdetail = users[referrerAddress];
        if (_userdetail.referrer != referrerAddress) {
            if (!users[_userdetail.referrer].activeLevels[level]) {
                partnerType = 4;
            } else if (_referrerdetail.id < users[_userdetail.referrer].id) {
                partnerType = 2;
            } else if (_referrerdetail.id > users[_userdetail.referrer].id) {
                partnerType = 3;
            }
        } else {
            partnerType = 1;
        }
        if (users[referrerAddress].Matrix[level].referrals.length < 3) {
            emit NewUserPlace(
                userAddress,
                users[userAddress].id,
                referrerAddress,
                users[referrerAddress].id,
                1,
                level,
                uint8(users[referrerAddress].Matrix[level].referrals.length),
                block.timestamp,
                partnerType
            );
            return
                sendDaiDividends(
                    referrerAddress,
                    userAddress,
                    level,
                    levelPrice[level]
                );
        }
        emit NewUserPlace(
            userAddress,
            users[userAddress].id,
            referrerAddress,
            users[referrerAddress].id,
            1,
            level,
            3,
            block.timestamp,
            partnerType
        );
        //close matrix
        users[referrerAddress].Matrix[level].referrals = new address[](0);
        if (referrerAddress != owner) {
            //check referrer active level
            address freeReferrerAddress = findFreeReferrer(
                referrerAddress,
                level
            );
            if (
                users[referrerAddress].Matrix[level].currentReferrer !=
                freeReferrerAddress
            ) {
                users[referrerAddress]
                    .Matrix[level]
                    .currentReferrer = freeReferrerAddress;
            }

            users[referrerAddress].Matrix[level].reinvestCount++;
            emit Reinvest(
                referrerAddress,
                freeReferrerAddress,
                userAddress,
                1,
                level,
                block.timestamp
            );
            updateO3Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            sendDaiDividends(owner, userAddress, level, levelPrice[level]);
            users[owner].Matrix[level].reinvestCount++;
            emit Reinvest(
                owner,
                address(0),
                userAddress,
                1,
                level,
                block.timestamp
            );
        }
    }

    function updateO6Referrer(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        require(
            users[referrerAddress].activeLevels[level],
            "500. Referrer level is inactive"
        );
        uint8 partnerType;
        User memory _userdetail = users[userAddress];
        User memory _referrerdetail = users[referrerAddress];
        if (_userdetail.referrer != referrerAddress) {
            if (!users[_userdetail.referrer].activeLevels[level]) {
                partnerType = 4;
            } else if (_referrerdetail.id < users[_userdetail.referrer].id) {
                partnerType = 2;
            } else if (_referrerdetail.id > users[_userdetail.referrer].id) {
                partnerType = 3;
            }
        } else {
            partnerType = 1;
        }
        if (users[referrerAddress].Matrix[level].referrals.length < 2) {
            users[referrerAddress].Matrix[level].referrals.push(userAddress);
            emit NewUserPlace(
                userAddress,
                users[userAddress].id,
                referrerAddress,
                users[referrerAddress].id,
                2,
                level,
                uint8(users[referrerAddress].Matrix[level].referrals.length),
                block.timestamp,
                partnerType
            );
            //set current level
            users[userAddress].Matrix[level].currentReferrer = referrerAddress;
            if (referrerAddress == owner) {
                return
                    sendDaiDividends(
                        referrerAddress,
                        userAddress,
                        level,
                        levelPrice[level]
                    );
            }
            address ref = users[referrerAddress].Matrix[level].currentReferrer;
            users[ref].Matrix[level].secondLevelReferrals.push(userAddress);
            uint256 len = users[ref].Matrix[level].referrals.length;
            _referrerdetail = users[ref];
            if (_userdetail.referrer != ref) {
                if (_referrerdetail.id < users[_userdetail.referrer].id) {
                    partnerType = 2;
                } else if (
                    _referrerdetail.id > users[_userdetail.referrer].id
                ) {
                    partnerType = 3;
                }
            } else {
                partnerType = 1;
            }
            if (
                (len == 2) &&
                (users[ref].Matrix[level].referrals[0] == referrerAddress) &&
                (users[ref].Matrix[level].referrals[1] == referrerAddress)
            ) {
                if (
                    users[referrerAddress].Matrix[level].referrals.length == 1
                ) {
                    emit NewUserPlace(
                        userAddress,
                        _userdetail.id,
                        ref,
                        users[ref].id,
                        2,
                        level,
                        5,
                        block.timestamp,
                        partnerType
                    );
                } else {
                    emit NewUserPlace(
                        userAddress,
                        _userdetail.id,
                        ref,
                        users[ref].id,
                        2,
                        level,
                        6,
                        block.timestamp,
                        partnerType
                    );
                }
            } else if (
                (len == 1 || len == 2) &&
                users[ref].Matrix[level].referrals[0] == referrerAddress
            ) {
                if (
                    users[referrerAddress].Matrix[level].referrals.length == 1
                ) {
                    emit NewUserPlace(
                        userAddress,
                        _userdetail.id,
                        ref,
                        users[ref].id,
                        2,
                        level,
                        3,
                        block.timestamp,
                        partnerType
                    );
                } else {
                    emit NewUserPlace(
                        userAddress,
                        _userdetail.id,
                        ref,
                        users[ref].id,
                        2,
                        level,
                        4,
                        block.timestamp,
                        partnerType
                    );
                }
            } else if (
                len == 2 &&
                users[ref].Matrix[level].referrals[1] == referrerAddress
            ) {
                if (
                    users[referrerAddress].Matrix[level].referrals.length == 1
                ) {
                    emit NewUserPlace(
                        userAddress,
                        _userdetail.id,
                        ref,
                        users[ref].id,
                        2,
                        level,
                        5,
                        block.timestamp,
                        partnerType
                    );
                } else {
                    emit NewUserPlace(
                        userAddress,
                        _userdetail.id,
                        ref,
                        users[ref].id,
                        2,
                        level,
                        6,
                        block.timestamp,
                        partnerType
                    );
                }
            }
            return updateO6ReferrerSecondLevel(userAddress, ref, level);
        }
        users[referrerAddress].Matrix[level].secondLevelReferrals.push(
            userAddress
        );
        if (users[referrerAddress].Matrix[level].closedPart != address(0)) {
            if (
                (users[referrerAddress].Matrix[level].referrals[0] ==
                    users[referrerAddress].Matrix[level].referrals[1]) &&
                (users[referrerAddress].Matrix[level].referrals[0] ==
                    users[referrerAddress].Matrix[level].closedPart)
            ) {
                updateO6(userAddress, referrerAddress, level, true);
                return
                    updateO6ReferrerSecondLevel(
                        userAddress,
                        referrerAddress,
                        level
                    );
            } else if (
                users[referrerAddress].Matrix[level].referrals[0] ==
                users[referrerAddress].Matrix[level].closedPart
            ) {
                updateO6(userAddress, referrerAddress, level, true);
                return
                    updateO6ReferrerSecondLevel(
                        userAddress,
                        referrerAddress,
                        level
                    );
            } else {
                updateO6(userAddress, referrerAddress, level, false);
                return
                    updateO6ReferrerSecondLevel(
                        userAddress,
                        referrerAddress,
                        level
                    );
            }
        }
        if (users[referrerAddress].Matrix[level].referrals[1] == userAddress) {
            updateO6(userAddress, referrerAddress, level, false);
            return
                updateO6ReferrerSecondLevel(
                    userAddress,
                    referrerAddress,
                    level
                );
        } else if (
            users[referrerAddress].Matrix[level].referrals[0] == userAddress
        ) {
            updateO6(userAddress, referrerAddress, level, true);
            return
                updateO6ReferrerSecondLevel(
                    userAddress,
                    referrerAddress,
                    level
                );
        }
        if (
            users[users[referrerAddress].Matrix[level].referrals[0]]
                .Matrix[level]
                .referrals
                .length <=
            users[users[referrerAddress].Matrix[level].referrals[1]]
                .Matrix[level]
                .referrals
                .length
        ) {
            updateO6(userAddress, referrerAddress, level, false);
        } else {
            updateO6(userAddress, referrerAddress, level, true);
        }
        updateO6ReferrerSecondLevel(userAddress, referrerAddress, level);
    }

    function updateO6(
        address userAddress,
        address referrerAddress,
        uint8 level,
        bool x2
    ) private {
        uint8 partnerType;
        if (!x2) {
            users[users[referrerAddress].Matrix[level].referrals[0]]
                .Matrix[level]
                .referrals
                .push(userAddress);
            address firstlevel = users[referrerAddress].Matrix[level].referrals[
                0
            ];
            User storage _userdetail = users[userAddress];
            User storage _referrerdetail = users[firstlevel];
            if (_userdetail.referrer != firstlevel) {
                if (_referrerdetail.id < users[_userdetail.referrer].id) {
                    partnerType = 2;
                } else if (
                    _referrerdetail.id > users[_userdetail.referrer].id
                ) {
                    partnerType = 3;
                }
            } else {
                partnerType = 1;
            }
            uint8 partner2;
            _referrerdetail = users[referrerAddress];
            if (_userdetail.referrer != referrerAddress) {
                if (!users[_userdetail.referrer].activeLevels[level]) {
                    partnerType = 4;
                } else if (
                    _referrerdetail.id < users[_userdetail.referrer].id
                ) {
                    partner2 = 2;
                } else if (
                    _referrerdetail.id > users[_userdetail.referrer].id
                ) {
                    partner2 = 3;
                }
            } else {
                partner2 = 1;
            }
            emit NewUserPlace(
                userAddress,
                _userdetail.id,
                firstlevel,
                users[firstlevel].id,
                2,
                level,
                uint8(users[firstlevel].Matrix[level].referrals.length),
                block.timestamp,
                partnerType
            );
            emit NewUserPlace(
                userAddress,
                _userdetail.id,
                referrerAddress,
                users[referrerAddress].id,
                2,
                level,
                2 + uint8(users[firstlevel].Matrix[level].referrals.length),
                block.timestamp,
                partner2
            );
            _userdetail.Matrix[level].currentReferrer = firstlevel;
        } else {
            users[users[referrerAddress].Matrix[level].referrals[1]]
                .Matrix[level]
                .referrals
                .push(userAddress);
            address firstlevel = users[referrerAddress].Matrix[level].referrals[
                1
            ];
            User storage _userdetail = users[userAddress];
            User storage _referrerdetail = users[firstlevel];
            if (_userdetail.referrer != firstlevel) {
                if (_referrerdetail.id < users[_userdetail.referrer].id) {
                    partnerType = 2;
                } else if (
                    _referrerdetail.id > users[_userdetail.referrer].id
                ) {
                    partnerType = 3;
                }
            } else {
                partnerType = 1;
            }
            uint8 partner2;
            _referrerdetail = users[referrerAddress];
            if (_userdetail.referrer != referrerAddress) {
                if (!users[_userdetail.referrer].activeLevels[level]) {
                    partnerType = 4;
                } else if (
                    _referrerdetail.id < users[_userdetail.referrer].id
                ) {
                    partner2 = 2;
                } else if (
                    _referrerdetail.id > users[_userdetail.referrer].id
                ) {
                    partner2 = 3;
                }
            } else {
                partner2 = 1;
            }
            emit NewUserPlace(
                userAddress,
                _userdetail.id,
                firstlevel,
                users[firstlevel].id,
                2,
                level,
                uint8(users[firstlevel].Matrix[level].referrals.length),
                block.timestamp,
                partnerType
            );
            emit NewUserPlace(
                userAddress,
                _userdetail.id,
                referrerAddress,
                users[referrerAddress].id,
                2,
                level,
                4 + uint8(users[firstlevel].Matrix[level].referrals.length),
                block.timestamp,
                partner2
            );
            _userdetail.Matrix[level].currentReferrer = firstlevel;
        }
    }

    function updateO6ReferrerSecondLevel(
        address userAddress,
        address referrerAddress,
        uint8 level
    ) private {
        if (
            users[referrerAddress].Matrix[level].secondLevelReferrals.length < 4
        ) {
            return
                sendDaiDividends(
                    referrerAddress,
                    userAddress,
                    level,
                    levelPrice[level]
                );
        }
        address[] memory memoryO6 = users[
            users[referrerAddress].Matrix[level].currentReferrer
        ].Matrix[level].referrals;
        if (memoryO6.length == 2) {
            if (
                memoryO6[0] == referrerAddress || memoryO6[1] == referrerAddress
            ) {
                users[users[referrerAddress].Matrix[level].currentReferrer]
                    .Matrix[level]
                    .closedPart = referrerAddress;
            } else if (memoryO6.length == 1) {
                if (memoryO6[0] == referrerAddress) {
                    users[users[referrerAddress].Matrix[level].currentReferrer]
                        .Matrix[level]
                        .closedPart = referrerAddress;
                }
            }
        }

        users[referrerAddress].Matrix[level].referrals = new address[](0);
        users[referrerAddress]
            .Matrix[level]
            .secondLevelReferrals = new address[](0);
        users[referrerAddress].Matrix[level].closedPart = address(0);

        if (
            !users[referrerAddress].activeLevels[level + 1] &&
            level != LAST_LEVEL
        ) {
            users[referrerAddress].Matrix[level].blocked = true;
        }

        users[referrerAddress].Matrix[level].reinvestCount++;

        if (referrerAddress != owner) {
            address freeReferrerAddress = findFreeReferrer(
                referrerAddress,
                level
            );

            emit Reinvest(
                referrerAddress,
                freeReferrerAddress,
                userAddress,
                2,
                level,
                block.timestamp
            );
            updateO6Referrer(referrerAddress, freeReferrerAddress, level);
        } else {
            emit Reinvest(
                owner,
                address(0),
                userAddress,
                2,
                level,
                block.timestamp
            );
            sendDaiDividends(owner, userAddress, level, levelPrice[level]);
        }
    }

    function findFreeReferrer(address userAddress, uint8 level)
        public
        view
        returns (address)
    {
        while (true) {
            if (users[users[userAddress].referrer].activeLevels[level]) {
                return users[userAddress].referrer;
            }
            userAddress = users[userAddress].referrer;
        }
    }

    function usersactiveLevels(address userAddress, uint8 level)
        public
        view
        returns (bool)
    {
        return users[userAddress].activeLevels[level];
    }

    function get3XMatrix(address userAddress, uint8 level)
        public
        view
        returns (
            address,
            address[] memory,
            uint256,
            bool
        )
    {
        return (
            users[userAddress].Matrix[level].currentReferrer,
            users[userAddress].Matrix[level].referrals,
            users[userAddress].Matrix[level].reinvestCount,
            users[userAddress].Matrix[level].blocked
        );
    }

    function getMatrix(address userAddress, uint8 level)
        public
        view
        returns (
            address,
            address[] memory,
            address[] memory,
            bool,
            uint256,
            address
        )
    {
        return (
            users[userAddress].Matrix[level].currentReferrer,
            users[userAddress].Matrix[level].referrals,
            users[userAddress].Matrix[level].secondLevelReferrals,
            users[userAddress].Matrix[level].blocked,
            users[userAddress].Matrix[level].reinvestCount,
            users[userAddress].Matrix[level].closedPart
        );
    }

    function isUserExists(address user) public view returns (bool) {
        return (users[user].id != 0);
    }

    function sendDaiDividends(
        address userAddress,
        address _from,
        uint8 level,
        uint256 amount
    ) private {
        uint256 creditamount = amount;
        if (
            users[userAddress].activeLevels[level + 1] ||
            users[userAddress].activeLevels[12]
        ) {
            creditamount = amount;
        } else {
            productfund += amount / 4;
            creditamount = (amount * 3) / 4;
            require(
                tokencontract.transferFrom(
                    msg.sender,
                    address(this),
                    amount / 4
                ),
                "Amount transfer failed"
            );
        }
        users[userAddress].Income += creditamount;
        require(
            tokencontract.transferFrom(msg.sender, userAddress, creditamount),
            "Amount transfer failed"
        );

        emit SentDividends(
            _from,
            users[_from].id,
            userAddress,
            users[userAddress].id,
            level,
            block.timestamp
        );
    }

    function bytesToAddress(bytes memory bys)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    // function setAdminFee(uint _fees) public payable {
    //     require(msg.sender == owner,"Permission Denied");
    //     adminFee = _fees;
    // }
    function safeWithdraw() public payable {
        require(msg.sender == owner, "Permission Denied");
        owner.transfer(address(this).balance);
    }

    function settotaldistributionallowed(uint256 _num) public payable {
        require(msg.sender == owner, "Permission Denied");
        totaldistributionallowed = _num;
    }

    function safeWithdrawToken(address _tokenaddress) public payable {
        require(msg.sender == owner, "Permission Denied");
        IERC20 token = IERC20(_tokenaddress);
        token.transfer(owner, token.balanceOf(address(this)));
    }
}