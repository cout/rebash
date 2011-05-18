SyntabEntryStruct = Struct.new(
    :cword, :cspecl, :cshbrk, :cblank, :cbsdquote, :cglob, :cxglob,
    :cspecvar, :cquote, :cxquote, :cexp, :cbshdoc, :cshmeta, :cshglob,
    :csubstop, :cbackq)
class SyntabEntry < SyntabEntryStruct
  def initialize(*flags)
    flags.each { |flag| self[flag] = true }
  end
end

SH_SYNTAXTAB = Hash.new { |h, c| h[c] = SyntabEntry.new(:cword) }
SH_SYNTAXTAB[?\001] = SyntabEntry.new(:cspecl)
SH_SYNTAXTAB[?\t] = SyntabEntry.new(:cshbrk, :cblank)
SH_SYNTAXTAB[?\n] = SyntabEntry.new(:cshbrk, :cbsdquote)
SH_SYNTAXTAB[?\s] = SyntabEntry.new(:cshbrk, :cblank)
SH_SYNTAXTAB[?!] = SyntabEntry.new(:cxglob, :cspecvar)
SH_SYNTAXTAB[?"] = SyntabEntry.new(:cquote, :cbsdquote, :cxquote)
SH_SYNTAXTAB[?#] = SyntabEntry.new(:cspecvar)
SH_SYNTAXTAB[?$] = SyntabEntry.new(:cexp, :cbsdquote, :cbshdoc, :cspecvar)
SH_SYNTAXTAB[?&] = SyntabEntry.new(:cshmeta, :cshbrk)
SH_SYNTAXTAB[?'] = SyntabEntry.new(:cquote, :cxquote)
SH_SYNTAXTAB[?(] = SyntabEntry.new(:cshmeta, :cshbrk)
SH_SYNTAXTAB[?)] = SyntabEntry.new(:cshmeta, :cshbrk)
SH_SYNTAXTAB[?*] = SyntabEntry.new(:cglob, :cshglob, :cspecvar)
SH_SYNTAXTAB[?+] = SyntabEntry.new(:cxglob, :csubstop)
SH_SYNTAXTAB[?-] = SyntabEntry.new(:cxglob, :csubstop)
SH_SYNTAXTAB[?;] = SyntabEntry.new(:cshmeta, :cshbrk)
SH_SYNTAXTAB[?<] = SyntabEntry.new(:cshmeta, :cshbrk, :cexp)
SH_SYNTAXTAB[?=] = SyntabEntry.new(:csubstop)
SH_SYNTAXTAB[?>] = SyntabEntry.new(:cshmeta, :cshbrk, :cexp)
SH_SYNTAXTAB[?@] = SyntabEntry.new(:cxglob, :cspecvar)
SH_SYNTAXTAB[?[] = SyntabEntry.new(:cglob)
SH_SYNTAXTAB[?\\] = SyntabEntry.new(:cbsdquote, :cbshdoc, :cxquote)
SH_SYNTAXTAB[?]] = SyntabEntry.new(:cglob)
SH_SYNTAXTAB[?`] = SyntabEntry.new(:cbackq, :cquote, :cbsdquote, :cbshdoc, :cxquote)
SH_SYNTAXTAB[?|] = SyntabEntry.new(:cshmeta, :cshbrk)
SH_SYNTAXTAB[?\177] = SyntabEntry.new(:cspecl)
