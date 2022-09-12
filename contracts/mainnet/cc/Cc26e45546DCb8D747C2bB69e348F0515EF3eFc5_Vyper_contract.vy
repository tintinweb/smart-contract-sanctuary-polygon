# https://proofivy.com
# Vyper 0.3.6

event PublicCommit:
    sender: indexed(address)
    hash: String[46]
    commit_count: uint256

event PublicMessage:
    sender: indexed(address)
    message: String[333]
    public_message_count: uint256

event GuildFounded:
    guild: String[300]

event GuildMemberCommit:
    guild: String[300]
    sender: indexed(address)
    hash: String[46]
    guild_commit_count: uint256

event GuildMemberMessage:
    guild: String[300]
    sender: indexed(address)
    message: String[333]
    guild_message_count: uint256

contract_owner: address

public_commit_price: public(uint256)
public_message_price: public(uint256)

public_commit_counter: public(uint256)
public_commit_senders: public(HashMap[uint256, address])
public_commits: public(HashMap[uint256, String[46]])

public_message_counter: public(uint256)
public_message_senders: public(HashMap[uint256, address])
public_messages: public(HashMap[uint256, String[333]])

guilds: public(HashMap[String[300], bool])
guild_admins: public(HashMap[String[300], HashMap[address, bool]])
guild_aspiring_members: public(HashMap[String[300], HashMap[address, bool]])
guild_members: public(HashMap[String[300], HashMap[address, bool]])

guild_commit_counter: public(HashMap[String[300], uint256])
guild_commit_senders: public(HashMap[String[300], HashMap[uint256, address]])
guild_commits: public(HashMap[String[300], HashMap[uint256, String[46]]])

guild_message_counter: public(HashMap[String[300], uint256])
guild_message_senders: public(HashMap[String[300], HashMap[uint256, address]])
guild_messages: public(HashMap[String[300], HashMap[uint256, String[333]]])


@external
def __init__():
    self.contract_owner = msg.sender
    self.public_commit_price = 5_000_000_000_000_000_000
    self.public_message_price = 10_000_000_000_000_000_000


@external
def change_owner(_contract_owner: address):
    assert msg.sender == self.contract_owner, 'You must own the contract'
    self.contract_owner = _contract_owner


@external
def set_public_commit_price(_commit_price: uint256):
    assert msg.sender == self.contract_owner, 'You must own the contract'
    self.public_commit_price = _commit_price


@external
def set_public_message_price(_message_price: uint256):
    assert msg.sender == self.contract_owner, 'You must own the contract'
    self.public_message_price = _message_price


@external
@payable
def public_commit(hash: String[46]):
    assert msg.value >= self.public_commit_price, 'Insufficient funds'
    send(self.contract_owner, msg.value)
    self.public_commit_counter += 1
    self.public_commit_senders[self.public_commit_counter] = msg.sender
    self.public_commits[self.public_commit_counter] = hash
    log PublicCommit(msg.sender, hash, self.public_commit_counter)


@external
@payable
def public_message(message: String[333]):
    assert msg.value >= self.public_message_price, 'Insufficient funds'
    self.public_message_counter += 1
    self.public_message_senders[self.public_message_counter] = msg.sender
    self.public_messages[self.public_message_counter] = message
    log PublicMessage(msg.sender, message, self.public_message_counter)


@external
def found_guild(guild: String[300], first_admin: address):
    assert msg.sender == self.contract_owner, 'You must own the contract'
    assert not self.guilds[guild], 'Guild name already in use'
    self.guilds[guild] = True
    self.guild_admins[guild][first_admin] = True
    self.guild_members[guild][first_admin] = True
    log GuildFounded(guild)


@external
def add_admin(guild: String[300], admin: address):
    assert msg.sender == self.contract_owner, 'You must own the contract'
    self.guild_admins[guild][admin] = True


@external
def remove_admin(guild: String[300], admin: address):
    assert msg.sender == self.contract_owner, 'You must own the contract'
    self.guild_admins[guild][admin] = False


@external
def aspire_membership(guild: String[300]):
    assert self.guilds[guild], 'Guild does not exist'
    self.guild_aspiring_members[guild][msg.sender] = True


@external
def remove_aspiring_membership(guild: String[300]):
    assert self.guilds[guild], 'Guild does not exist'
    self.guild_aspiring_members[guild][msg.sender] = False


@external
def add_member(guild: String[300], member: address):
    assert self.guild_admins[guild][msg.sender], 'Not an admin'
    assert self.guild_aspiring_members[guild][member], 'New member should first be an aspiring member'
    self.guild_members[guild][member] = True


@external
def remove_member(guild: String[300], member: address):
    assert self.guild_admins[guild][msg.sender], 'Not an admin'
    self.guild_members[guild][member] = False


@external
def guild_commit(guild: String[300], hash: String[46]):
    assert self.guild_members[guild][msg.sender], 'Not a member'
    self.guild_commit_counter[guild] += 1
    self.guild_commit_senders[guild][self.guild_commit_counter[guild]] = msg.sender
    self.guild_commits[guild][self.guild_commit_counter[guild]] = hash
    log GuildMemberCommit(guild, msg.sender, hash, self.guild_commit_counter[guild])


@external
def guild_message(guild: String[300], message: String[333]):
    assert self.guild_members[guild][msg.sender], 'Not a member'
    self.guild_message_counter[guild] += 1
    self.guild_message_senders[guild][self.guild_message_counter[guild]] = msg.sender
    self.guild_messages[guild][self.guild_message_counter[guild]] = message
    log GuildMemberMessage(guild, msg.sender, message, self.guild_message_counter[guild])