// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract Share{

    // let address: 0xMsgSender
    struct Access{
        address user;
        bool hasAccess;
    }

    mapping(address=>string[]) value;
    // storing url
    // eg: user01: 0xAbc,
    //             uploads: imgUrl01_Abc, imgUrl02_Abc, etc
    //     user02: 0xDef,
    //             uploads: imgUrl01_Def, etc
    //     THEN -> Value stores users details (above one): value[user01], value[user02], etc
 
    mapping(address=>mapping(address=>bool)) ownership;
    // 2D array kindof stating the access, Like user1 has given access to user 3 & user 4 then value will be true
    // Eg: u01 u02 u03 u04
    // u01      F   T   T
    // u02  T       T   F
    // u03  F   T       T
    // u04  T   F   F

    mapping(address=> Access[]) accessList;
    // For fetching the list for the current user showing to whom the access has been given

    mapping(address=>mapping(address=>bool)) history;
    // Previous Data / cookies:
    // In case of again and again allowance and denial of access, inorder to prevent pushing same data again and again
    // As we are using the blockchain here itself as a database (not other services like node or any else)

    function addUser(address _user, string memory url) external{
        value[_user].push(url);
    }

    function allowAccess(address user) external{
        // current user let: 0xMsgSender
        
        // 0xMsgSender allows user let: 0xAbc
        ownership[msg.sender][user] = true;

        // if already had accessed in past and comes again for permissions
        if(history[msg.sender][user]){
            for(uint i=0; i<accessList[msg.sender].length ; i++){
                if(accessList[msg.sender][i].user == user){
                    accessList[msg.sender][i].hasAccess = true;
                }
            }
        }
        else{
            accessList[msg.sender].push(Access(user, true));
            history[msg.sender][user] = true; //updating previous data / cookies for new users
        }

    }

    function revoke(address user) public{
        ownership[msg.sender][user] = false;
        for(uint i=0; i<accessList[msg.sender].length; i++){
            if(accessList[msg.sender][i].user == user){
                accessList[msg.sender][i].hasAccess = false; //revoking access
            }
        }
    }

    function display(address _user) external view returns(string[] memory){
        require(_user==msg.sender || ownership[_user][msg.sender], "You Don't have access, Ask For Access");
        return value[_user];
    }

    function shareAccess() public view returns(Access[] memory){
        return accessList[msg.sender];
    }
}