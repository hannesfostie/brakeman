#Sexp changes from ruby_parser
#and some changes for caching hash value and tracking 'original' line number
#of a Sexp.
class Sexp
  attr_reader :paren

  def paren
    @paren ||= false
  end

  def value
    raise "multi item sexp" if size > 2
    last
  end

  def to_sym
    self.value.to_sym
  end

  alias :node_type :sexp_type
  alias :values :sexp_body # TODO: retire

  alias :old_push :<<
  alias :old_line :line
  alias :old_line_set :line=
  alias :old_file_set :file=
  alias :old_comments_set :comments=
  alias :old_compact :compact
  alias :old_fara :find_and_replace_all
  alias :old_find_node :find_node

  def original_line line = nil
    if line
      @my_hash_value = nil
      @original_line = line
      self
    else
      @original_line ||= nil
    end
  end

  def hash
    #There still seems to be some instances in which the hash of the
    #Sexp changes, but I have not found what method call is doing it.
    #Of course, Sexp is subclasses from Array, so who knows what might
    #be going on.
    @my_hash_value ||= super
  end

  def line num = nil
    @my_hash_value = nil if num
    old_line(num)
  end

  def line= *args
    @my_hash_value = nil
    old_line_set(*args)
  end

  def file= *args
    @my_hash_value = nil
    old_file_set(*args)
  end

  def compact
    @my_hash_value = nil
    old_compact
  end

  def find_and_replace_all *args
    @my_hash_value = nil
    old_fara(*args)
  end

  def find_node *args
    @my_hash_value = nil
    old_find_node(*args)
  end

  def paren= arg
    @my_hash_value = nil
    @paren = arg
  end

  def comments= *args
    @my_hash_value = nil
    old_comments_set(*args)
  end

  def each_sexp
    self.each do |e|
      yield e if Sexp === e
    end
  end

  def expect *types
    unless types.include? self.node_type
      raise WrongSexpError, "Expected #{types.join ' or '} but given #{self.node_type}", caller[1..-1]
    end
  end

  def target
    expect :call
    self[1]
  end

  def method
    expect :call
    self[2]
  end

  def args
    expect :call
    #For new ruby_parser
    #if self[3]
    #  self[3..-1]
    #else
    #  []
    #end

    #For old ruby_parser
    if self[3]
      self[3][1..-1]
    else
      []
    end
  end

  def condition
    expect :if
    self[1]
  end

  def then_clause
    expect :if
    self[2]
  end

  def else_clause
    expect :if
    self[3]
  end

  def block_call
    expect :iter, :call_with_block
    self[1]
  end

  def block
    expect :iter, :call_with_block
    self[-1]
  end

  def block_args
    expect :iter, :call_with_block
    self[2]
  end

  def lhs
    expect :lasgn
    self[1]
  end

  def rhs
    expect :lasgn
    self[2]
  end
end

#Invalidate hash cache if the Sexp changes
[:[]=, :clear, :collect!, :compact!, :concat, :delete, :delete_at,
  :delete_if, :drop, :drop_while, :fill, :flatten!, :replace, :insert,
  :keep_if, :map!, :pop, :push, :reject!, :replace, :reverse!, :rotate!,
  :select!, :shift, :shuffle!, :slice!, :sort!, :sort_by!, :transpose, 
  :uniq!, :unshift].each do |method|

  Sexp.class_eval <<-RUBY
    def #{method} *args
      @my_hash_value = nil
      super
    end
    RUBY
end

class WrongSexpError < RuntimeError; end