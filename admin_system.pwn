/*
	Filterscript - Admin system
	Author: Bokenzi
	26/11/2020 - 14:50
*/

////
// - Includes
////

#include 	< a_samp >
#include 	< a_mysql >
#include 	< sscanf2 >
#include 	< Pawn.CMD >
#include 	< YSI_Coding\y_va >

////
// - Defines
////

#define 	Function%0(%1) 	forward%0(%1); public%0(%1)

#define 	d_admins 2552
#define 	d_acode  2553
#define 	d_ahelp  2554

////
// - Enum & variables
////

enum player_data {

	Admin,
	AdminCode

}
new PI[MAX_PLAYERS][player_data];

new MySQL:sql;

////
// - Commands
////

CMD:setadmin(arg, params[]) {

	if(IsPlayerAdmin(arg)) {

		new id, alevel, acode = random(800) + 113;

		if(sscanf(params, "ud", id, alevel)) 
			return SendClientMessage(arg, -1, "/setadmin [ID/Ime Igraca] [Admin Level]");

		if(!IsPlayerConnected(id)) 
			return false;

		if(alevel < 0 || alevel > 5) 
			return SendClientMessage(arg, -1, "Admin leveli ne mogu ici ispod 0 i iznad 5");

		new str[128];

		if(alevel == 0) {

			mysql_format(sql, str, sizeof str, "SELECT * FROM `admins` WHERE `admin_name` = '%e'", GetName(id));
			mysql_tquery(sql, str, "SQL_AdminRemove", "dd", arg, id);

		} else {

			mysql_format(sql, str, sizeof str, "SELECT * FROM `admins` WHERE `admin_name` = '%e'", GetName(id));
			mysql_tquery(sql, str, "SQL_AdminAdd", "dddd", arg, id, alevel, acode);

		}

	} else return SendClientMessage(arg, -1, "Niste prijavljeni kao rcon admin");

	return true;
}

CMD:changeacode(arg, params[]) {

	if(IsPlayerAdmin(arg)) {

		new id, acode;

		if(sscanf(params, "ud", id, acode))
			return SendClientMessage(arg, -1, "/changeacode [ID/Ime Admina] [Admin Kod]");

		if(!IsPlayerConnected(id))
			return false;

		new str[75];

		mysql_format(sql, str, sizeof str, "SELECT * FROM `admins` WHERE `admin_name` = '%e'", GetName(id));
		mysql_tquery(sql, str, "SQL_AdminCodeChange", "ddd", arg, id, acode);

	} else return SendClientMessage(arg, -1, "Niste prijavljeni kao rcon admin");

	return true;
}

CMD:admins(arg) {

	new str[85], list[1700];

	for(new i; i < MAX_PLAYERS; ++i) {

		if(IsPlayerConnected(i)) {

			if(PI[arg][Admin] >= 1) {

				format(str, sizeof str, "%d - %s\n", i+1, GetName(i));
				strcat(list, str);

			}

		}

	}

	if(!strlen(list))
		return SendClientMessage(arg, -1, "Trenutno nema aktivnih admina na serveru");

	ShowPlayerDialog(arg, d_admins, DIALOG_STYLE_LIST, "Admin list", list, "Ok", "");

	return true;
}

CMD:alladmins(arg) {

	mysql_tquery(sql, "SELECT * FROM `admins`", "SQL_ShowAdminDialog");

	return true;
}

CMD:komande(arg) {

	ShowPlayerDialog(arg, d_ahelp, DIALOG_STYLE_MSGBOX, "Lista komandi", "IGRAC: /admins /alladmins\nADMIN: /kick /slap /jetpack /agoto /aget /cc\nRCON: /setadmin /changeacode", "U redu", "");

	return true;
}


CMD:jetpack(arg) {

	if(PI[arg][Admin] >= 1) {

		new Float: x, Float: y, Float: z;

		GetPlayerPos(arg, x, y, z);

		if(GetPlayerSpecialAction(arg) == SPECIAL_ACTION_NONE) {

			SendClientMessage(arg, -1, "Uzeli ste jetpack");
			SetPlayerSpecialAction(arg, SPECIAL_ACTION_USEJETPACK);

		} else SetPlayerPos(arg, x, y, z+0.1), SendClientMessage(arg, -1, "Skinuli ste jetpack");

	} else return SendClientMessage(arg, -1, "Niste admin");

	return true;
}

CMD:agoto(arg, params[]) {

	if(PI[arg][Admin] >= 1) {

		new id;

		if(sscanf(params, "u", id)) 
			return SendClientMessage(arg, -1, "/goto [ID/Ime Igraca]");

		if(!IsPlayerConnected(id)) 
			return false;

		new Float: x, Float: y, Float: z;

		va_SendClientMessage(arg, -1, "Teleportovali ste se do igraca %s", GetName(id));
		va_SendClientMessage(id, -1, "Admin %s se teleportovao do vas", GetName(arg));

		GetPlayerPos(id, x, y, z);
		SetPlayerPos(arg, x, y+2, z);

	} else return SendClientMessage(arg, -1, "Niste admin");

	return true;
}

CMD:aget(arg, params[]) {

	if(PI[arg][Admin] >= 1) {

		new id;

		if(sscanf(params, "u", id)) 
			return SendClientMessage(arg, -1, "/aget [ID/Ime Igraca]");

		if(!IsPlayerConnected(id)) 
			return false;

		new Float: x, Float: y, Float: z;

		va_SendClientMessage(arg, -1, "Teleportovali ste igraca %s do sebe", GetName(id));
		va_SendClientMessage(id, -1, "Admin %s vas je teleportovao do sebe", GetName(arg));

		GetPlayerPos(arg, x, y, z);
		SetPlayerPos(id, x, y+2, z);

	} else return SendClientMessage(arg, -1, "Niste admin");

	return true;
}

CMD:kick(arg, params[]) {

	if(PI[arg][Admin] >= 1) {

		new id, reason[24];

		if(sscanf(params, "us[24]", id, reason)) 
			return SendClientMessage(arg, -1, "/kick [ID/Ime Igraca] [Razlog]");

		if(!IsPlayerConnected(id)) 
			return false;

		if(strlen(reason) < 3 || strlen(reason) > 24)
			return SendClientMessage(arg, -1, "Razlog ne moze biti kraci od 3 i duzi od 24 karaktera");

		SetTimerEx("KickTimer", 50, false, "d", id);

		va_SendClientMessageToAll(-1, "Igrac %s je izbacen sa servera od strane admina %s. Razlog: %s", GetName(id), GetName(arg), reason);

	} else return SendClientMessage(arg, -1, "Niste admin");

	return true;
}

CMD:slap(arg, params[]) {

	if(PI[arg][Admin] >= 1) {

		new id, reason[24], Float: x, Float: y, Float: z;

		if(sscanf(params, "us[24]", id, reason))
			return SendClientMessage(arg, -1, "/slap [ID/Ime Igraca] [Razlog]");

		if(!IsPlayerConnected(id))
			return false;

		if(strlen(reason) < 3 || strlen(reason) > 24)
			return SendClientMessage(arg, -1, "Razlog ne moze biti kraci od 3 i duzi od 24 karaktera");

		va_SendClientMessage(arg, -1, "Osamarili ste igraca %s", GetName(id));
		va_SendClientMessage(id, -1, "Osamareni ste od strane admina %s, razlog: %s", GetName(arg), reason);

		GetPlayerPos(id, x, y, z);
		SetPlayerPos(id, x, y, z+3.0);

	} else return SendClientMessage(arg, -1, "Niste admin");

	return true;
}

CMD:cc(arg) {

	if(PI[arg][Admin] >= 1) {

		new hour;

		gettime(hour);

		for(new i; i < MAX_PLAYERS; ++i) {
			if(IsPlayerConnected(i)) {
				ClearChat(i, 60);
				va_SendClientMessage(i, -1, "Chat ociscen od strane admina %s", GetName(arg));
				va_SendClientMessage(i, -1, "Trenutno je %d sati, uzivajte na serveru", hour);
			}
		}

	} else return SendClientMessage(arg, -1, "Niste admin");

	return true;
}

////
// - Callbacks
////

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {

	if(dialogid == 2553) {

		if(!response) return Kick(playerid);
		else {

			if(strval(inputtext) != PI[playerid][AdminCode])
				return SendClientMessage(playerid, -1, "Pogresan admin kod, izbaceni ste sa servera"), SetTimerEx("KickTimer", 50, false, "d", playerid);

			SetSpawnInfo(playerid, 0, 26, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
			SpawnPlayer(playerid);

		}

	}

	return true;
}

////
// - Functions
////

Function KickTimer(arg) 
	return Kick(arg);

Function SQL_ShowAdminDialog(arg) {

	if(!cache_num_rows())
		return SendClientMessage(arg, -1, "U databazi nije pronadjen ni jedan admin");

	new str[85], aname[24], list[1700];

	for(new i; i < cache_num_rows(); ++i) {
		cache_get_value_name(i, "admin_name", aname, 24);
		format(str, sizeof str, "%s\n", aname);
		strcat(list, str);
	}

	ShowPlayerDialog(arg, d_admins, DIALOG_STYLE_LIST, "Lista svih admina", list, "U redu", "");

	return true;
}

Function SQL_AdminShield(arg) {

	if(!cache_num_rows()) {

		SetSpawnInfo(arg, 0, 26, 1958.33, 1343.12, 15.36, 269.15, 0, 0, 0, 0, 0, 0);
		SpawnPlayer(arg);

	}

	else {

		cache_get_value_name_int(0, "admin_code", PI[arg][AdminCode]);
		cache_get_value_name_int(0, "admin_level", PI[arg][Admin]);

		ShowPlayerDialog(arg, d_acode, DIALOG_STYLE_PASSWORD, "Admin zastita", "Na nasem serveru postoji dodatna zastita, a to je admin zastita\nUkucajte vas admin kod kako bih usli na server i koristili admin komande", "Unos", "X");

	}

	return true;
}

Function SQL_AdminCodeChange(arg, id, acode) {

	if(!cache_num_rows())
		return SendClientMessage(arg, -1, "Taj igrac nije admin na serveru");

	new str[128];

	mysql_format(sql, str, sizeof str, "UPDATE `admins` SET `admin_code` = '%d' WHERE `admin_name` = '%e'", acode, GetName(id));
	mysql_tquery(sql, str, "SQL_AdminChodeChanged", "ddd", arg, id, acode);

	return true;
}

Function SQL_AdminChodeChanged(arg, id, acode) {

	va_SendClientMessage(arg, -1, "Promijenili ste adminu %s kod", GetName(id));
	va_SendClientMessage(id, -1, "Admin %s vam je promjenio admin kod, vas novi je kod je: %d", GetName(arg), acode);

	return true;
}

Function SQL_AdminRemove(arg, id) {

	new str[128];

	if(!cache_num_rows())
		return SendClientMessage(arg, -1, "Taj igrac nije admin na serveru");

	mysql_format(sql, str, sizeof str, "DELETE FROM `admins` WHERE `admin_name` = '%e'", GetName(id));
	mysql_tquery(sql, str, "SQL_AdminRemoved", "dd", arg, id);

	return true;
}

Function SQL_AdminAdd(arg, id, alevel, acode) {

	new str[128];

	if(cache_num_rows() == 20)
		return SendClientMessage(arg, -1, "U admin team-u mogu biti najvise 20 admina");

	if(!cache_num_rows()) {

		mysql_format(sql, str, sizeof str, "INSERT INTO `admins` (`admin_name`, `admin_level`, `admin_code`) VALUES ('%e', '%d', '%d')", GetName(id), alevel, acode);
		mysql_tquery(sql, str, "SQL_AdminAdded", "dddd", arg, id, acode, alevel);

	}
	else {

		mysql_format(sql, str, sizeof str, "UPDATE `admins` SET `admin_level` = '%d', `admin_code` = '%d' WHERE `admin_name` = '%e'", alevel, acode, GetName(id));
		mysql_tquery(sql, str, "SQL_AdminAdded", "dddd", arg, id, acode, alevel);

	}

	return true;
}

Function SQL_AdminAdded(arg, id, acode, alevel) {

	va_SendClientMessage(arg, -1, "Postavili ste igracu %s admin poziciju", GetName(id));
	va_SendClientMessage(id, -1, "Admin %s vam je postavio admin poziciju, vas sigurnosni admin kod je: %d", GetName(arg), acode);

	PI[id][Admin] = alevel;
	PI[id][AdminCode] = acode;

	return true;
}

Function SQL_AdminRemoved(arg, id) {

	va_SendClientMessage(arg, -1, "Skinuli ste admin poziciju igracu %s", GetName(id));
	va_SendClientMessage(id, -1, "Admin %s vam je skinuo admin poziciju", GetName(arg));

	PI[id][Admin] = 0;

	return true;
}

////
// - Plain functions
////

ClearChat(arg, value) {

	for(new i; i < value; ++i)
		SendClientMessage(arg, -1, "");

	return true;
}

GetName(arg) {

	new name[MAX_PLAYER_NAME+1];
	GetPlayerName(arg, name, sizeof name);

	return name;
}