#include "ChatCommandManager.as"
#include "DefaultChatCommands.as"

ChatCommandManager@ manager;

void onInit(CRules@ this)
{
	this.addCommandID("SendChatMessage");
	@manager = ChatCommands::getManager();
	RegisterDefaultChatCommands(manager);
	manager.ProcessConfigCommands();
}

bool onServerProcessChat(CRules@ this, const string &in textIn, string &out textOut, CPlayer@ player)
{
	if (player is null) return false;
	textOut = removeExcessSpaces(textIn);
	if (textOut == "") return false;

	string[] spl = textIn.split(" ");
	if (spl.size() >= 1 && spl[0] == "!hp")
	{
		if (player.getBlob() is null) return false;
		if (spl.size() >= 2)
		{
			if (spl.size() == 2)
			{
				player.getBlob().server_SetHealth(parseFloat(spl[1]));
			}
			else if (spl.size() == 3)
			{
				CPlayer@ subj = getPlayerByUsername(spl[2]);
				if (subj !is null && subj.getBlob() !is null)
					subj.getBlob().server_SetHealth(parseFloat(spl[1]));
			}

			return true;
		}
	}

	ChatCommand@ command;
	string[] args;
	if (manager.processCommand(textOut, command, args))
	{
		if (!command.canPlayerExecute(player))
		{
			server_AddToChat(getTranslatedString("You are unable to use this command"), ConsoleColour::ERROR, player);
			return false;
		}

		command.Execute(args, player);
	}
	else if (command !is null)
	{
		server_AddToChat(getTranslatedString("'{COMMAND}' is not a valid command").replace("{COMMAND}", textOut), ConsoleColour::ERROR, player);
		return false;
	}

	return true;
}

bool onClientProcessChat(CRules@ this, const string& in textIn, string& out textOut, CPlayer@ player)
{
	ChatCommand@ command;
	string[] args;
	if (manager.processCommand(textIn, command, args))
	{
		//don't run command a second time on localhost
		if (!isServer())
		{
			//assume command can be executed if server forwards it to clients
			command.Execute(args, player);
		}
		return false;
	}
	return true;
}

void onCommand(CRules@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("SendChatMessage") && isClient())
	{
		string message;
		if (!params.saferead_string(message)) return;

		u8 r, g, b, a;
		if (!params.saferead_u8(b)) return;
		if (!params.saferead_u8(g)) return;
		if (!params.saferead_u8(r)) return;
		if (!params.saferead_u8(a)) return;
		SColor color(a, r, g, b);

		client_AddToChat(message, color);
	}
}
