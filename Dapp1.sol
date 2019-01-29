pragma solidity ^0.5.3; //"first team",43,1,0,"i'm dev,hahaha"
pragma experimental ABIEncoderV2;
contract Main {
    enum teamRule { dictatorship, democratic, originator }  // maximum amount, subtotal everyone, who creat team
    gameConfig config;
    uint8[255] scores;
    uint16[] teams;
    mapping(address => member) public addr2member;
    mapping(uint16 => team) id2team;
    event history(uint16 indexed game, uint8 indexed round, uint block);
    struct gameConfig {
        address developer;
        uint8 currentRound; // the starting point is 1
        uint16 currentGame; // max 16777215
        uint16 nextTeamID;
        uint lastCharge;    // cost of building a team in wei
        uint currentCharge; // fibonacci number
        uint dateNode;      // defint endTime
    }
    struct team {
        string name;
        address payable[] members;
        teamRule rule;
        uint8 countryRegion;
        uint16 attackID;
        uint totalAmount;
        uint maxAttackAmount;
        mapping(uint16 => uint) subAmount;   // subtotal amount by attackID
    }
    struct teamSummary {
        string name;
        string message;
        teamRule rule;
        uint8 countryRegion;
        uint16 ID;
        uint16 attackID;
        uint totalAmount;
        uint maxAttackAmount;
        uint membersLength;
        effectiveAttack[] effectiveAttacks;
    }
    struct effectiveAttack {
        uint16 teamID;
        uint amount;
    }
    struct member {
        string message;
        uint16 attackID;
        uint16 teamID;  // joined team
        uint amount;    // joined amount
        uint bonus;
    }
    struct teamMember {
        address addr;
        string message;
        uint16 attackID;
        uint amount;
    }
    constructor(uint date) public {
        (config.developer, config.nextTeamID, config.lastCharge, config.currentCharge, config.dateNode) = (msg.sender, 1, 1000000000, 2000000000, date);
    }
    function newTeam(string memory name, uint8 countryRegion, teamRule rule, uint16 attackID, string memory message) public payable {
        require(msg.value > config.currentCharge, "The amount is not enough to build up a team.");
        require(addr2member[msg.sender].amount == 0, "You have been in fighting.");
        require(id2team[attackID].totalAmount > 0 || attackID == 0, "Your attackID error.");
        require(rule == teamRule.democratic || rule == teamRule.dictatorship || rule == teamRule.originator);
        //stateCheck();
        uint amount = msg.value - config.currentCharge;
        uint16 teamID = config.nextTeamID++;
        if(attackID == 0)
            attackID = config.nextTeamID;
        (id2team[teamID].name, id2team[teamID].countryRegion, id2team[teamID].rule, id2team[teamID].totalAmount, id2team[teamID].attackID) = (name, countryRegion, rule, amount, attackID);
        (teams[teams.length++], id2team[teamID].members[id2team[teamID].members.length++], addr2member[msg.sender].teamID, addr2member[msg.sender].attackID, addr2member[msg.sender].amount) = (teamID, msg.sender, teamID, attackID, amount);
        if(rule != teamRule.originator) {
            id2team[teamID].maxAttackAmount = amount;
            if(rule == teamRule.democratic)
                id2team[teamID].subAmount[attackID] = amount;
        }
        if(bytes(message).length > 0)
            addr2member[msg.sender].message = message;
        addr2member[config.developer].bonus += config.currentCharge;  // team building cost transfer to developer account
        (config.currentCharge, config.lastCharge) = (config.currentCharge + config.lastCharge, config.currentCharge);   // calculate next fibonacci number
    }
    function joinTeam(uint16 teamID, uint16 attackID, string memory message) public payable {
        require(msg.value > 0, "Your amount is empty.");
        require(addr2member[msg.sender].amount == 0 || addr2member[msg.sender].teamID == teamID, "You have been in fighting.");
        require(id2team[teamID].totalAmount > 0, "The team is not in currentRound.");
        require(id2team[attackID].totalAmount > 0 || attackID == config.nextTeamID, "Your attackID error.");
        //stateCheck();
        if(addr2member[msg.sender].amount == 0) // first time to join
            (addr2member[msg.sender].teamID, id2team[teamID].members[id2team[teamID].members.length++]) = (teamID, msg.sender);
        if(id2team[teamID].rule == teamRule.dictatorship) {
            addr2member[msg.sender].amount += msg.value;
            if(addr2member[msg.sender].amount >= id2team[teamID].maxAttackAmount)
                id2team[teamID].maxAttackAmount = addr2member[msg.sender].amount;
            if(id2team[teamID].attackID != attackID)
                id2team[teamID].attackID = attackID;
        }
        else if(id2team[teamID].rule == teamRule.democratic) {
            id2team[teamID].subAmount[addr2member[msg.sender].attackID] -= addr2member[msg.sender].amount;
            addr2member[msg.sender].amount += msg.value;
            id2team[teamID].subAmount[attackID] += addr2member[msg.sender].amount;
            subMax(teamID);
        }
        else if(id2team[teamID].rule == teamRule.originator) {
            addr2member[msg.sender].amount += msg.value;
            if (msg.sender == id2team[teamID].members[0] && id2team[teamID].attackID != attackID)
                id2team[teamID].attackID = attackID;
        }
        if(addr2member[msg.sender].attackID != attackID)    // different attack target
            addr2member[msg.sender].attackID = attackID;
        if(bytes(message).length > 0)
            addr2member[msg.sender].message = message;
        id2team[teamID].totalAmount += msg.value;
    }
    function attackTeam(uint16 attackID, string memory message) public {
        require(addr2member[msg.sender].amount > 0, "You are not in game.");
        require(id2team[attackID].totalAmount > 0 || attackID == config.nextTeamID, "Your attackID error.");
        uint16 teamID = addr2member[msg.sender].teamID;
        if(id2team[teamID].rule == teamRule.democratic) {
            id2team[teamID].subAmount[addr2member[msg.sender].attackID] -= addr2member[msg.sender].amount;
            id2team[teamID].subAmount[attackID] += addr2member[msg.sender].amount;
            subMax(teamID);
        }                                           // decide on subtotal everyone
        else if(id2team[teamID].rule == teamRule.dictatorship) {
            if(addr2member[msg.sender].amount >= id2team[teamID].maxAttackAmount)
                (id2team[teamID].maxAttackAmount, id2team[teamID].attackID) = (addr2member[msg.sender].amount, attackID);
        }                                           // decide on maximum amount
        else if(id2team[teamID].rule == teamRule.originator && id2team[teamID].members[0] == msg.sender)
            id2team[teamID].attackID = attackID;    // decide on originator
        addr2member[msg.sender].attackID = attackID;
        if(bytes(message).length > 0)
            addr2member[msg.sender].message = message;
    }
    function stateCheck() public {
        if(now >= config.dateNode + 1 days) {
            emit history(config.currentGame, config.currentRound, block.number);
            if(teams.length >= 2) { // goto next round
                uint16 eliminateIndex;  // eliminate Team's index number in teams arrary
                uint8 p;
                uint maxInjury;         // max injury
                uint denominator;       // total wei in current round
                uint[] memory injury = new uint[](teams.length);
                for(uint8 i = 0; i < teams.length; i++) {
                    denominator += id2team[teams[i]].totalAmount;
                    if(id2team[id2team[teams[i]].attackID].members.length > 0) {
                        injury[id2team[teams[i]].attackID] += id2team[teams[i]].totalAmount;
                        if(injury[id2team[teams[i]].attackID] > maxInjury)
                            (eliminateIndex, maxInjury, p) = (id2team[teams[i]].attackID, injury[id2team[teams[i]].attackID], i);
                    }
                }
                if(p < teams.length - 1)
                    teams[p] = teams[teams.length - 1];
                teams.length--;
                denominator -= id2team[eliminateIndex].totalAmount;
                uint numerator = id2team[eliminateIndex].totalAmount * 32 / 33;
                addr2member[config.developer].bonus += id2team[eliminateIndex].totalAmount - numerator;   // 3 percents developer fee
                for(uint8 t = 0; t < teams.length; t++) {   // promote
                    for(uint m = 0; m < id2team[teams[t]].members.length; m++)
                        addr2member[id2team[teams[t]].members[m]].bonus += addr2member[id2team[teams[t]].members[m]].amount * numerator / denominator;
                    if(id2team[id2team[teams[t]].attackID].totalAmount == 0) {
                        if(id2team[teams[t]].rule == teamRule.democratic)
                            subMax(teams[t]);
                        else if(id2team[teams[t]].rule == teamRule.dictatorship) {
                            uint16 ID;
                            uint maxAmount;
                            for(uint m = 0; m < id2team[teams[t]].members.length; m++) {
                                if(addr2member[id2team[teams[t]].members[m]].amount >= maxAmount && id2team[addr2member[id2team[teams[t]].members[m]].attackID].totalAmount >0)
                                    (ID, maxAmount) = (addr2member[id2team[teams[t]].members[m]].attackID, addr2member[id2team[teams[t]].members[m]].amount);
                            }
                            if(id2team[teams[t]].attackID != ID)
                                id2team[teams[t]].attackID = ID;
                            if(id2team[teams[t]].maxAttackAmount != maxAmount)
                                id2team[teams[t]].maxAttackAmount = maxAmount;
                        }
                    }
                }
                for(uint m = 0; m < id2team[eliminateIndex].members.length; m++)
                    delete addr2member[id2team[eliminateIndex].members[m]].amount;
                delete id2team[eliminateIndex];
                config.currentRound++;
            }
            else {                  // goto next game
                for(uint m = 0; m < id2team[teams[0]].members.length; m++) {
                    addr2member[id2team[teams[0]].members[m]].bonus += addr2member[id2team[teams[0]].members[m]].amount;
                    delete addr2member[id2team[teams[0]].members[m]].amount;
                }
                delete id2team[teams[0]].members;
                delete id2team[teams[0]].totalAmount;
                if(id2team[teams[0]].rule != teamRule.originator) {
                    delete id2team[teams[0]].maxAttackAmount;
                    if(id2team[teams[0]].rule == teamRule.democratic)
                        delete id2team[teams[0]].subAmount[config.nextTeamID];
                }
                scores[id2team[teams[0]].countryRegion]++;
                (id2team[teams[0]].attackID, config.currentRound, config.nextTeamID, config.lastCharge, config.currentCharge) = (config.nextTeamID, 1, 0, 1000000000, 2000000000);
                config.currentGame++;
            }
            config.dateNode += 1 days;
        }
    }
    function withdraw(address payable target) public {
        require(addr2member[msg.sender].bonus > 0 , "Balance is not enough.");
        //stateCheck();
        addr2member[msg.sender].bonus = 0;
        target.transfer(addr2member[msg.sender].bonus);
    }
    function responseGlobal() public view returns(uint16, uint8, uint, uint8[255] memory) {
        return (config.currentGame, config.currentRound, config.dateNode, scores);
    }
    function responseTeams() public view returns(teamSummary[] memory, uint16, uint) {
        teamSummary[] memory teamsSummary = new teamSummary[](teams.length);
        for(uint8 t = 0; t < teams.length; t++) {
            uint16 ID = teams[t];
            effectiveAttack[] memory effectiveAttacks = new effectiveAttack[](teams.length);
            for(uint8 a = 0; a < teams.length; a++) {
                if(a != t)
                    effectiveAttacks[a] = effectiveAttack({teamID:teams[a], amount:id2team[ID].subAmount[teams[a]]});
                else
                    effectiveAttacks[a] = effectiveAttack({teamID:config.nextTeamID, amount:id2team[ID].subAmount[config.nextTeamID]});
            }
            (teamsSummary[t].ID, teamsSummary[t].name,                                                teamsSummary[t].message, teamsSummary[t].countryRegion, teamsSummary[t].rule)
            =(               ID,     id2team[ID].name, addr2member[id2team[ID].members[id2team[ID].members.length-1]].message, id2team[ID].countryRegion,     id2team[ID].rule);
            (teamsSummary[t].attackID, teamsSummary[t].totalAmount, teamsSummary[t].maxAttackAmount, teamsSummary[t].effectiveAttacks, teamsSummary[t].membersLength)
            =(   id2team[ID].attackID,     id2team[ID].totalAmount,     id2team[ID].maxAttackAmount,                 effectiveAttacks,    id2team[ID].members.length);
        }
        return (teamsSummary, config.nextTeamID, config.currentCharge);
    }
    function responseMembers(uint16 ID) public view returns(teamMember[] memory teamMembers) {
        teamMembers = new teamMember[](id2team[ID].members.length);
        for(uint m = 0; m < id2team[ID].members.length; m++)
            teamMembers[m] = teamMember({addr:id2team[ID].members[m], message:addr2member[id2team[ID].members[m]].message, attackID:addr2member[id2team[ID].members[m]].attackID, amount:addr2member[id2team[ID].members[m]].amount});
    }
    function subMax(uint16 teamID) private {
        uint16 ID;
        uint maxAmount;
        for(uint8 t = 0; t < teams.length; t++) {
            if(teams[t] == teamID) {
                if(id2team[teamID].subAmount[config.nextTeamID] >= maxAmount)
                    (ID, maxAmount) = (config.nextTeamID, id2team[teamID].subAmount[config.nextTeamID]);
            }
            else {
                if(id2team[teamID].subAmount[teams[t]] >= maxAmount)
                    (ID, maxAmount) = (teams[t], id2team[teamID].subAmount[teams[t]]);
            }
        }
        if(id2team[teamID].attackID != ID)
            id2team[teamID].attackID = ID;
        if(id2team[teamID].maxAttackAmount != maxAmount)
            id2team[teamID].maxAttackAmount = maxAmount;
    }
}
