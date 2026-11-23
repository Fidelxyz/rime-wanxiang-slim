# Reverse-lookup codes carry no tone, keeping exact matches first

`table_translator` always lists exact matches before completions, and weights only order candidates within each group.
Upstream appends the target character's tone to every reverse-lookup code so that no input ever matches exactly and all
candidates compete by weight alone; users then type the tone to pick out the exactly matched character.

This fork does not introduce reverse-lookup tone filtering. Reverse lookup exists to find characters whose pronunciation
the user does not know, so the user cannot know their tone either.

This fork keeps the default exact-match-first ordering. Characters looked up by decomposition tend to be rare and
low-weighted. Ranking by weight alone would push such a character behind higher-weighted completions even after its
decomposition is fully typed. With exact matches first, the target character ranks first once its decomposition is
complete.

This fork therefore strips the tone suffix and keeps the weights when syncing the upstream dictionary, so weights still
order each group.
