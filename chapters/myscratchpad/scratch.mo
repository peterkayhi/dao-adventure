import Iter "mo:base/Iter";
let iter = Iter.range(1, 3);
let mappedIter = Iter.map(iter, func (x : Nat) : Nat { x * 2 });
assert(?2 == mappedIter.next());
assert(?4 == mappedIter.next());
assert(?6 == mappedIter.next());
assert(null == mappedIter.next());



members = Iter.toArray(Iter.map<Member, Text>(members.vals(), func(member : Member) { member.name }));