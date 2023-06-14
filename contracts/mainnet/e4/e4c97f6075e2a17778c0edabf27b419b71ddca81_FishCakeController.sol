/**
 *Submitted for verification at polygonscan.com on 2023-06-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }
}

contract FishCakeController is Context {
    address constant public FccTokenAddr = address(0x67AAFdb3aD974A6797D973F00556c603485F7158);

    struct ActivityInfo {
        uint256 activityId;       // 活动ID
        address businessAccount;       // 发起人账户（商家0x...）
        string businessName;     // 商家名称
        string activityContent;     // 活动内容
        string latitudeLongitude;   // 经纬度，以_分割经纬度
        uint256 activityCreateTime;       // 活动创建时间
        uint256 activityDeadLine;       // 活动结束时间
        uint8 dropType;     // 奖励规则：1表示平均获得  2表示随机
        uint256 dropNumber;     // 奖励份数
        uint256 minDropAmt;     // 当dropType为1时，填0，为2时，填每份最少领取数量
        uint256 maxDropAmt;     // 当dropType为1时，填每份奖励数量，为2时，填每份最多领取数量，奖励总量根据该字段 * 奖励份数确定
        uint256 alreadyDropAmts;         // 总共已奖励数量
        uint256 alreadyDropNumber;        // 总共已奖励份数
        uint8 activityStatus;     // 活动状态：1表示进行中  2表示已结束
    }
    ActivityInfo[] public activityInfoArrs; // 所有活动数组

    uint256[] public activityInfoChangedIdx; // 状态有改变的下标

    struct DropInfo {
        uint256 activityId;       // 活动ID
        address userAccount;       // 发起人账户（商家0x...）
        uint256 dropTime;       // 获奖时间
        uint256 dropAmt;     // 获奖数量
    }
    DropInfo[] public dropInfoArrs; // 所有获奖数组
    mapping(uint256 => mapping(address => bool)) public activityDropedToAccount; // 活动ID => 用户 => 是否已获得过奖励

    /*
        增加活动，任何人都可以增加
        参数：
        _businessName 商家名称
        _activityContent 活动内容
        _latitudeLongitude 商家地址经纬度，以_分割经纬度
        _activityDeadLine 活动结束时间，需传TimeStamp到后端（如：1683685034）
        _totalDropAmts  总奖励数量，根据_maxDropAmt * _dropNumber得到，不用用户输入 （调用合约时，需将用户输入的数字 * 10的18次方）
        _dropType     奖励规则：1表示平均获得  2表示随机
        _dropNumber      奖励份数
        _minDropAmt     当dropType为1时，填0，为2时，填每份最少领取数量  （调用合约时，需将用户输入的数字 * 10的18次方）
        _maxDropAmt     当dropType为1时，填每份奖励数量，为2时，填每份最多领取数量，奖励总量根据该字段 * 奖励份数确定  （调用合约时，需将用户输入的数字 * 10的18次方）

        返回值：
        _ret   是否成功
        _activityId  活动ID

        注：前端调用该方法前，需先调用FCCToken的approve方法，授权本合约地址，访问使用者钱包的FCCToken访问权限。
        具体授权数字，使用 _maxDropAmt * 10的18次方 * _dropNumber
    */
    function activityAdd(
            string memory _businessName, string memory _activityContent, string memory _latitudeLongitude, uint256 _activityDeadLine, 
            uint256 _totalDropAmts, uint8 _dropType, uint256 _dropNumber, uint256 _minDropAmt, uint256 _maxDropAmt) public returns(bool _ret, uint256 _activityId) {

        require(_dropType == 2 || _dropType == 1, "Drop Type Error.");
        require(_totalDropAmts > 0, "Drop Amount Error.");

        require(_totalDropAmts == _maxDropAmt * _dropNumber, "Drop Number Not Meet Total Drop Amounts.");

        // 转币到本合约锁定
        TransferHelper.safeTransferFrom(FccTokenAddr, _msgSender(), address(this), _totalDropAmts);     

        ActivityInfo memory ai = ActivityInfo({
            activityId: activityInfoArrs.length + 1, 
            businessAccount: _msgSender(),
            businessName: _businessName,
            activityContent: _activityContent,
            latitudeLongitude: _latitudeLongitude,
            activityCreateTime: block.timestamp,
            activityDeadLine: _activityDeadLine,
            dropType: _dropType,
            dropNumber: _dropNumber,
            minDropAmt: _minDropAmt,
            maxDropAmt: _maxDropAmt,
            alreadyDropAmts: 0,
            alreadyDropNumber: 0,
            activityStatus: 1
        });
        activityInfoArrs.push(ai);

        _ret = true;
        _activityId = ai.activityId;
    }


    event ActivityFinish(uint256 indexed _activityId);
    /*
        商家结束活动
        参数：
        _activityId  活动ID

        返回值：
        _ret  是否成功
    */
    function activityFinish(uint256 _activityId) public returns(bool _ret) {

        ActivityInfo storage ai = activityInfoArrs[_activityId - 1];

        require(ai.businessAccount == _msgSender(), "Not The Owner.");
        require(ai.activityStatus == 1, "Activity Status Error.");

        ai.activityStatus = 2;

        if (ai.maxDropAmt * ai.dropNumber > ai.alreadyDropAmts) {
            TransferHelper.safeTransfer(FccTokenAddr, _msgSender(), ai.maxDropAmt * ai.dropNumber - ai.alreadyDropAmts);     
        } 

        activityInfoChangedIdx.push(_activityId - 1);

        emit ActivityFinish(_activityId);      

        _ret = true;
    }


    /*
        奖励发放（商家给会员发放奖励）

        参数：
        _activityId  活动ID
        _userAccount 终端用户地址
        _dropAmt     奖励数量，如果活动的dropType是随机时，需填写该数量，因为合约随机数生成非常消耗资源，平均获得时，无需填写  ;     // 奖励规则：1表示平均获得  2表示随机

        返回值：
        _ret 是否成功
    */
    function drop(uint256 _activityId, address _userAccount, uint256 _dropAmt) external returns(bool _ret) {
        require(activityDropedToAccount[_activityId][_userAccount] == false, "User Has Droped.");

        ActivityInfo storage ai = activityInfoArrs[_activityId - 1];

        require(ai.activityStatus == 1, "Activity Status Error.");
        require(ai.businessAccount == _msgSender(), "Not The Owner.");

        if (ai.dropType == 2) {
            require(_dropAmt <= ai.maxDropAmt && _dropAmt >= ai.minDropAmt, "Drop Amount Error.");
        } else {
            _dropAmt = ai.maxDropAmt;
        }

        require(ai.dropNumber > ai.alreadyDropNumber, "Exceeded the number of rewards.");
        require(ai.maxDropAmt * ai.dropNumber >= _dropAmt + ai.alreadyDropAmts, "The reward amount has been exceeded.");

        TransferHelper.safeTransfer(FccTokenAddr, _userAccount, _dropAmt);

        activityDropedToAccount[_activityId][_userAccount] = true;


        DropInfo memory di = DropInfo({
            activityId: _activityId, 
            userAccount: _userAccount,
            dropTime: block.timestamp,
            dropAmt: _dropAmt
        });
        dropInfoArrs.push(di);

        ai.alreadyDropAmts += _dropAmt;
        ai.alreadyDropNumber ++;

        activityInfoChangedIdx.push(_activityId - 1);

        _ret = true;
    }
}