import os
from types import ModuleType
from typing import ValuesView
import ruamel
from ruamel import yaml
from ruamel.yaml import YAML
import re

from ruamel.yaml.main import parse
from riscv_config.warl import warl_interpreter

def load_yaml(foo):

    yaml = YAML(typ='rt')
    yaml.default_flow_style = False
    yaml.allow_unicode = True
    yaml.compact(seq_seq=False, seq_map=False)
    yaml.indent = 4
    yaml.block_seq_indent = 2

    try:
        with open(foo, 'r') as file:
            return yaml.load(file)
    except ruamel.yaml.constructor.DuplicateKeyError as msg:
        logger = logging.getLogger(__name__)
        error = '\n'.join(str(msg).split('\n')[2:-7])
        logger.error(error)
        raise SystemExit

warl_type_and_func= '''
enum WARL_range_mode = {
  WARL_Unchanged,
  WARL_Nextup,
  WARL_Nextdown,
  WARL_Nearup,
  WARL_Neardown,
  WARL_Largest,
  WARL_Smallest,
  WARL_Addr
}

union WARL_range_entry = {
  WARL_range_value : nat,
  WARL_range_interval : (nat, nat)
}

struct WARL_range_type = {
  mask : nat,
  delta : nat,
  values : list(WARL_range_entry)
}

struct WARL_bitmask = {
  mask : nat, /* XXX consider using bits('n) */
  default_val : nat
}

union WARL_either = {
  WARL_range_list : list(WARL_range_type),
  WARL_bitmask : WARL_bitmask
}

val is_value_in_range : (nat, list(WARL_range_entry)) -> bool
function is_value_in_range (value, warl_range) = match(warl_range) {
  [||]    => false,
  v :: vs => match (v) {
    WARL_range_value(v)       => value == v | is_value_in_range(value, vs),
    WARL_range_interval(l, u) => ((l <= value ) & (value <= u)) | is_value_in_range(value, vs)
  }
}

val is_value_in_rangelist : forall 'n, 'n > 0 . (bits('n), list(WARL_range_type)) -> bool effect {escape}
function is_value_in_rangelist (value, list) = match(list) {
  [||]    => true,
  v :: vs => is_value_in_range(unsigned(value & to_bits('n, v.mask)), v.values) & is_value_in_rangelist(value, vs)
}

val WARL_range_max : (list(WARL_range_entry)) -> nat effect {escape}
function WARL_range_max (warl_range) = match(warl_range) {
  [||] => throw Error_not_implemented("Empty WARL range"),
  v :: [||]  =>
    match (v) {
      WARL_range_value(v)       => v,
      WARL_range_interval(l, u) => u
    },
  v :: vs    =>
    let tail_max : nat = WARL_range_max(vs) in
    match (v) {
      WARL_range_value(v)       => if v > tail_max then v else tail_max,
      WARL_range_interval(l, u) => if u > tail_max then u else tail_max
    }

}

val WARL_range_min : (list(WARL_range_entry)) -> nat effect {escape}
function WARL_range_min (warl_range) = match(warl_range) {
  [||] => throw Error_not_implemented("Empty WARL range"),
  v :: [||]  =>
    match (v) {
      WARL_range_value(v)       => v,
      WARL_range_interval(l, u) => l
    },
  v :: vs    =>
    let tail_min : nat = WARL_range_min(vs) in
    match (v) {
      WARL_range_value(v)       => if v < tail_min then v else tail_min,
      WARL_range_interval(l, u) => if u < tail_min then u else tail_min
    }
}

val WARL_range_nextup : (nat, list(WARL_range_entry)) -> nat effect {escape}
function WARL_range_nextup (value, warl_range) = match(warl_range) {
  [||] => throw Error_not_implemented("Empty WARL range"),
  v :: [||]  =>
    match (v) {
      WARL_range_value(v)       => v,
      WARL_range_interval(l, u) => {
        if value >= l & value <= u  then value
        else if value > u  then u
        else l
      }
    },
  v :: vs    =>
    let tail_nextup : nat = WARL_range_nextup(value, vs) in
    match (v) {
      WARL_range_value(v)       => {
        if v >= value & v < tail_nextup then v
        else if v >= value & tail_nextup < value then v
        else if v <= value & v > tail_nextup then v
        else  tail_nextup
      },
      WARL_range_interval(l, u) => {
        if value >= l & value <= u  then value
        else if value > u & u > tail_nextup then u
        else if  value < l & l < tail_nextup then l
        else tail_nextup
      }
    }
}

val WARL_range_nextdown : (nat, list(WARL_range_entry)) -> nat effect {escape}
function WARL_range_nextdown (value, warl_range) = match(warl_range) {
  [||] => throw Error_not_implemented("Empty WARL range"),
  v :: [||]  =>
    match (v) {
      WARL_range_value(v)       => v,
      WARL_range_interval(l, u) => {
        if value >= l & value <= u  then value
        else if value > u  then u
        else l
      }
    },
  v :: vs    =>
    let tail_nextdown : nat = WARL_range_nextdown(value, vs) in
    match (v) {
      WARL_range_value(v)       => {
        if v <= value & v > tail_nextdown then v
        else if v <= value & tail_nextdown > value then v
        else if v >= value & v < tail_nextdown then v
        else  tail_nextdown
      },
      WARL_range_interval(l, u) => {
        if value >= l & value <= u  then value
        else if value > u & u > tail_nextdown then u
        else if  value < l & l < tail_nextdown then l
        else tail_nextdown
      }
    }
}

val WARL_range_nearup : (nat, list(WARL_range_entry)) -> nat effect {escape}
function WARL_range_nearup (value, warl_range) = {
  nextup = WARL_range_nextup(value, warl_range);
  nextdown = WARL_range_nextup(value, warl_range);
  if nextup <= value then nextup
  else if nextdown >= value then nextdown
  else if (nextup - value) <= (value - nextdown) then nextup
  else nextdown
}

val WARL_range_neardown : (nat, list(WARL_range_entry)) -> nat effect {escape}
function WARL_range_neardown (value, warl_range) = {
  nextup = WARL_range_nextup(value, warl_range);
  nextdown = WARL_range_nextup(value, warl_range);
  if nextup <= value then nextup
  else if nextdown >= value then nextdown
  else if (nextup - value) < (value - nextdown) then nextup
  else nextdown
}

val legalize_warl_range : forall 'n, 'n > 0 . (bits('n), bits('n), WARL_range_type, WARL_range_mode) -> bits('n) effect {escape}
function legalize_warl_range(current_val, written_val, legal_range, mode) = {
  match(mode) {
    WARL_Unchanged => current_val & to_bits('n, legal_range.mask),
    WARL_Largest   => to_bits('n, WARL_range_max(legal_range.values)),
    WARL_Smallest  => to_bits('n, WARL_range_min(legal_range.values)),
    WARL_Nextup    => to_bits('n, WARL_range_nextup(unsigned(current_val), legal_range.values)),
    WARL_Nextdown  => to_bits('n, WARL_range_nextdown(unsigned(current_val), legal_range.values)),
    WARL_Nearup    => to_bits('n, WARL_range_nearup(unsigned(current_val), legal_range.values)),
    WARL_Neardown  => to_bits('n, WARL_range_neardown(unsigned(current_val), legal_range.values)),
    WARL_Addr      => written_val ^ shiftl(to_bits('n, 1), 'n - 1)
  }
}

val legalize_warl_rangelist : forall 'n, 'n > 0 . (bits('n), bits('n), list(WARL_range_type), WARL_range_mode, bits('n)) -> bits('n) effect {escape}
function legalize_warl_rangelist(current_val, written_val, legal_range_list, mode, msmask) = {
  match(mode) {
    WARL_Unchanged => current_val,
    WARL_Nearup    => {
      nextup : bits('n) = legalize_warl_rangelist(current_val, written_val, legal_range_list, WARL_Nextup, msmask);
      nextdown : bits('n) = legalize_warl_rangelist(current_val, written_val, legal_range_list, WARL_Nextdown, msmask);
      cur : bits('n) = written_val & not_vec(msmask);
      if (nextup == nextdown) then nextup
      else if ((unsigned(nextup) - unsigned(cur)) <= (unsigned(cur) - unsigned(nextdown))) then nextup
      else nextdown
    },
    WARL_Neardown  => {
      nextup : bits('n) = legalize_warl_rangelist(current_val, written_val, legal_range_list, WARL_Nextup, msmask);
      nextdown : bits('n) = legalize_warl_rangelist(current_val, written_val, legal_range_list, WARL_Nextdown, msmask);
      cur : bits('n) = written_val & not_vec(msmask);
      if (nextup == nextdown) then nextup
      else if ((unsigned(nextup) - unsigned(cur)) < (unsigned(cur) - unsigned(nextdown))) then nextup
      else nextdown
    },
    WARL_Addr      => written_val ^ shiftl(to_bits('n, 1), 'n - 1),
    _ => {
      match(legal_range_list) {
      [||]    => to_bits('n, 0),
      v :: vs => {
        cur = written_val & to_bits('n, v.mask);
        msfields : bits('n) = legalize_warl_range(current_val, cur , v, mode);
        match(mode) {
        WARL_Largest   => msfields | legalize_warl_rangelist(current_val, written_val, vs, mode, msmask | to_bits('n, v.mask)),
        WARL_Smallest  => msfields | legalize_warl_rangelist(current_val, written_val, vs, mode, msmask | to_bits('n, v.mask)),
        WARL_Nextup    => {
          if (unsigned(msfields) > unsigned(cur)) then msfields | legalize_warl_rangelist(current_val, written_val, vs, WARL_Smallest, msmask | to_bits('n, v.mask))
          else if (unsigned(msfields) < unsigned(cur)) then msfields | legalize_warl_rangelist(current_val, written_val, vs, WARL_Largest, msmask | to_bits('n, v.mask))
          else {
            lsfields : bits('n) = legalize_warl_rangelist(current_val, written_val, vs, mode, msmask | to_bits('n, v.mask));
            value : bits('n) = msfields | lsfields;
            if (unsigned(value) > unsigned(written_val & not_vec(msmask))) then value
            else {
              msfields = legalize_warl_range(current_val, to_bits('n, unsigned(cur) + v.delta) , v, mode);
              if (unsigned(msfields) >= unsigned(cur)) then  msfields | legalize_warl_rangelist(current_val, written_val, vs, WARL_Smallest, msmask | to_bits('n, v.mask))
              else value
            }
          }
        },
        WARL_Nextdown  => {
          cur = written_val & to_bits('n, v.mask);
          msfields : bits('n) = legalize_warl_range(current_val, cur , v, mode);
          if (unsigned(msfields) > unsigned(cur)) then msfields | legalize_warl_rangelist(current_val, written_val, vs, WARL_Smallest, msmask | to_bits('n, v.mask))
          else if (unsigned(msfields) < unsigned(cur)) then msfields | legalize_warl_rangelist(current_val, written_val, vs, WARL_Largest, msmask | to_bits('n, v.mask))
          else {
            lsfields : bits('n) = legalize_warl_rangelist(current_val, written_val, vs, mode, msmask | to_bits('n, v.mask));
            value : bits('n) = msfields | lsfields;
            if (unsigned(value) < unsigned(written_val & (not_vec(msmask)))) then value
            else {
              msfields = legalize_warl_range(current_val, to_bits('n, unsigned(cur) - v.delta) , v, mode);
              if (unsigned(msfields) <= unsigned(cur)) then  msfields | legalize_warl_rangelist(current_val, written_val, vs, WARL_Largest, msmask | to_bits('n, v.mask))
              else value
            }
          }
        }
      }

      }
      }
    }
  }
}

val legalize_warl_bitmask : forall 'n, 'n > 0 & 'n <= 64 . (bits('n), WARL_bitmask) -> bits('n)
function legalize_warl_bitmask (value, mask) =
  (value & to_bits('n, mask.mask)) | to_bits('n, mask.default_val)

val legalize_warl_either : forall 'n, 'n > 0  & 'n <= 64 . (bits('n), bits('n), WARL_either, WARL_range_mode) -> bits('n) effect {escape}
function legalize_warl_either(current_val, written_val, warl_either, mode) =
  match (warl_either) {
    WARL_range_list(r) => legalize_warl_rangelist(current_val, written_val, r, mode, to_bits('n, 0)),
    WARL_bitmask(b) => legalize_warl_bitmask(written_val, b)
}
'''

def getMask( x ):
    return x[0]

def parse_values(value_str, field_mask, lsb, not_in):
  parse_str = ''
  if ":" in value_str: # range is specified
    [base, bound] = value_str.split(':')
    if 'x' in base:
      base = int(base, 16)
    base = int(base) << lsb
    if 'x' in bound:
      bound = int(bound, 16)
    bound = int(bound) << lsb
    if base > field_mask | bound > field_mask:
      print(reg + ' [base : bound] is illegal\n')
      raise SystemExit
    if not_in:
      if base != 0:
        parse_str += 'WARL_range_interval(unsigned(0x%x), unsigned(0x%x)), '%(0, base - (1 << lsb))
      if bound != field_mask:
        parse_str += 'WARL_range_interval(unsigned(0x%x), unsigned(0x%x)), '%(bound + (1 << lsb),
                      field_mask)
    else:
      parse_str += 'WARL_range_interval(unsigned(0x%x), unsigned(0x%x)), '%(base, bound)
  else:
    l_vals = value_str.split(',')
    values = []
    last = 0
    for i in l_vals :
      if 'x' in i:
        i = int(i, 16)
      i = int(i) << lsb
      if i > field_mask:
        print(reg + ' legal list is illegal\n')
        raise SystemExit
      values.append(i)

    values.sort()

    for i in values:
      if not_in:
        if i != last:
          parse_str += 'WARL_range_interval(unsigned(0x%x), unsigned(0x%x)), '%(last << lsb,
                        i - (1<< lsb))
        last = i + (1 << lsb)
      else:
        parse_str += 'WARL_range_value(unsigned(0x%x)), ' %i

    if not_in:
      if last <= field_mask:
        parse_str += 'WARL_range_interval(unsigned(0x%x), unsigned(0x%x)), '%(last, field_mask)
  return parse_str[:-2]

def parse_field_range(legal_str):
  warl_range_temp = '''
    struct {{
      mask = {0},
      delta = {1},
      values = [|{2}|]
    }}: WARL_range_type'''

  warl_bitmask_temp = '''
    struct {{
      mask = {0},
      default_val = {1}
    }}: WARL_bitmask'''
  exp  = re.compile('\[(?P<csr_ind>.*?)\]\s*(?P<csr_op>.*?)\s*\[(?P<csr_vals>.*?)\]')
  csr_search = exp.findall(legal_str)
  range_field= ''
  range_list = []
  for part in csr_search:
    (csr_ind, csr_op, csr_vals) = part
    msb = csr_ind.split(':')[0].strip()
    lsb = csr_ind.split(':')[-1].strip()
    bitmask = True if 'bitmask' in csr_op else False
    field_mask = (1 << (int(msb) + 1)) - (1 << int(lsb))
    parse_str = ''
    if not bitmask: # if its not a bitmask
      parse_str = parse_values(csr_vals, field_mask, int(lsb), 'not' in csr_op)
      range_list.append([field_mask, warl_range_temp.format('unsigned(0x%x)'%field_mask,
                        'unsigned(0x%x)'%(1 << int(lsb)), parse_str)])
    else:
      [mask, fixed] = csr_vals.split(',')
      if 'x' in mask:
        mask = 'unsigned(' + mask.strip() + ')'
      if 'x' in fixed:
        fixed = 'unsigned(' + fixed.strip() + ')'
      if range_field == '' and range_list == [] :
        range_field =  warl_bitmask_temp.format(str(mask), str(fixed)) + ', '
        break
      else:
        print('cannot mix bitmask and range\n')

  if 'bitmask' not in legal_str:
    range_list.sort(key = getMask, reverse=True)
    for d in range_list:
      range_field  += d[1] + ', '
  return range_field[: -2]

def legalize_without_dependencies(reg, field, field_yaml):
  global func_str
  legalize_field = '''
function legalize_{0}_{1}(o : {2}, v : {2}) -> {2} = {{
  m : {2} = v;
  {3}  m
}}
'''

  wr_value_temp = '''let wr_value_rangelist : list(WARL_range_type) = [|{0}|];\n'''

  warl_range_temp = '''let warl_range_list : list(WARL_range_type) = [|{0}|];\n'''

  legalize_field_strs=''

  warl = field_yaml['type']['warl']
  if len(warl['legal']) > 1:
    print('warl without dependence can only have one legal entry')
    raise SystemExit

  range_list = parse_field_range(warl['legal'][0])

  if 'bitmask' not in warl['legal'][0]:
    legalize_field_strs +=  warl_range_temp.format(range_list) + '\n'
    legalize_field_strs += '  if (~ (is_value_in_rangelist(v, warl_range_list))) then {\n'
    for i in range(len(warl['wr_illegal'])):
      op = re.findall(r'\s*wr_val\s*in\s*\[(.*?)\]',
                              warl['wr_illegal'][i])
      if op != []:
        parse_str = parse_values(op[0], Oxffffffffffffffff, 1, False)
        wr_value_temp.format(parse_str)
        legalize_field_strs += '  if is_value_in_range(v, wr_value_rangelist) then '
        op2 = re.split(r'\->', warl['wr_illegal'][i])
        mode = op2[1]
      else:
        mode = warl['wr_illegal'][i]
      if '0x' in mode:
        legalize_field_strs += '    m = ' + mode + ';'
      else:
        legalize_field_strs += '    m = legalize_warl_either(o , m, WARL_range_list(warl_range_list), WARL_' + mode.title() + ');'
      legalize_field_strs +='\n  };\n'
  else:
      legalize_field_strs += 'm = legalize_warl_either(o , m, WARL_bitmask(' + range_list + '), WARL_Unchanged);\n'


  func_str += legalize_field.format(reg.lower(), field.upper(), 'bits(' + str(int(field_yaml['msb']) - int(field_yaml['lsb']) + 1) + ')', legalize_field_strs)

def search_dependency_field(csr, field, depend_fields):
  leaf_dependencies = []
  for d in depend_fields:
    leaf_dependencies.append(d.split('::')[-1])
  if field not in leaf_dependencies:
    print('cannot find dpendency field ' + field + ' in ' + str(leaf_dependencies) + '\n')
    raise SystemExit
  field_val = depend_fields[leaf_dependencies.index(field)]
  if '::' in field_val:
    csr_name = field_val.split('::')[0].strip()
    field_name = field_val.split('::')[-1].strip()
    return csr_name + '.' + field_name.upper() + '()'
  else:
    return field_val + '->bits()'

def parse_dependency(csr, dep_str, depend_fields):
  cond_str = ''
  exp  = re.compile('(?P<csr>.*?)\[(?P<csr_ind>.*?)\]\s*(?P<csr_op>.*?)\s*\[(?P<csr_vals>.*?)\]')
  csr_search = exp.findall(dep_str)
  for part in csr_search:
    (field, csr_ind, csr_op, csr_vals) = part
    field = search_dependency_field(csr, field.strip(), depend_fields)
    val = 'unsigned(' + field + '[' + csr_ind.split(':')[0] + ' .. ' + csr_ind.split(':')[-1] + '])'
    bitmask = True if 'bitmask' in csr_op else False
    range_str = ''
    if not bitmask: # if its not a bitmask
      if ":" in csr_vals: # range is specified
        [base, bound] = csr_vals.split(':')
        if 'x' in base:
          base = int(base.strip(), 16)
        base = int(base)
        if 'x' in bound:
          bound = int(bound.strip(), 16)
        bound = int(bound)
        range_str += 'WARL_range_interval(unsigned(0x%x), unsigned(0x%x)),'%(base, bound)
      else:
        l_vals = csr_vals.split(',')
        for i in l_vals :
          if 'x' in i:
            i = int(i, 16)
          i = int(i)
          range_str += 'WARL_range_value(unsigned(0x%x)),' %i
      cond_str += 'is_value_in_range(' + val + ',[|' + range_str[:-1] + '|]) & \n'
    else:
      print('cannot support bitmask in dpendency list\n')
      raise SystemExit
  return cond_str[:-4]

def legalize_with_dependencies(reg, field, field_yaml):
  global func_str
  legalize_field = '''
function legalize_{0}_{1}(o : {2}, v : {2}) -> {2} = {{
  m : {2} = v;
  {3}
  m
}}
'''

  warl_range_temp = '''  let warl_range_list : list(WARL_range_type) = [|{0}|];'''

  legalize_field_strs='illegal: bool = false;\n  let warl_range_list : list(WARL_range_type) = [||];\n'

  warl = field_yaml['type']['warl']

  for legal_str in warl['legal']:

    if '->' in legal_str:
      dep_str = legal_str.split('->')[0]
      csr_str = legal_str.split('->')[1]
      dep_str = parse_dependency(reg, dep_str, warl['dependency_fields'])
      legalize_field_strs += '  if ' + dep_str + ' then {\n  '
    else:
      csr_str = legal_str;
      legalize_field_strs += '  {\n  '

    range_list = parse_field_range(csr_str)
    if 'bitmask' not in csr_str:
      legalize_field_strs +=  warl_range_temp.format(range_list) + '\n'

      legalize_field_strs += '    if (~(is_value_in_rangelist(v, warl_range_list))) then illegal = true;\n  };\n\n'
    else:
      legalize_field_strs += '    m = legalize_warl_either(o , m, WARL_bitmask(' + range_list + '), WARL_Unchanged);\n  };\n\n'

  for illegal_str in warl['wr_illegal']:
    if '->' in illegal_str:
      dep_str = illegal_str.split('->')[0]
      mode = illegal_str.split('->')[1].strip()
      op = re.findall(r'\s*wr_val\s*in\s*\[(.*?)\]',
                          dep_str)
      dep_str = parse_dependency(reg, dep_str, warl['dependency_fields'])
      if dep_str != '':
        dep_str = ' & ' + dep_str

      if op != []:
        wr_value_temp = '''  let wr_value_rangelist : list(WARL_range_type) = [|{0}|];'''
        parse_str = parse_values(op[0], Oxffffffffffffffff, 1, False)
        wr_value_temp.format(parse_str)
        legalize_field_strs += '  if illegal == true' + dep_str + ' & is_value_in_range(v, wr_value_rangelist) then '
      else:
        legalize_field_strs += '  if illegal == true' + dep_str + ' then \n'
    else:
      legalize_field_strs += '  if illegal == true then \n'
      mode = illegal_str.strip()

    if '0x' in mode:
      legalize_field_strs += '    m = ' + mode + ';'
    else:
      legalize_field_strs += '    m = legalize_warl_either(o , m, WARL_range_list(warl_range_list), WARL_' + mode.title() + ');\n'

  func_str += legalize_field.format(reg.lower(), field.upper(), 'bits(' + str(int(field_yaml['msb']) - int(field_yaml['lsb']) + 1) + ')', legalize_field_strs)

def parse_warl_value(reg, field, field_yaml):
    warl = field_yaml['type']['warl']
    dependencies = warl['dependency_fields']
    if dependencies == []:
      legalize_without_dependencies(reg, field, field_yaml)
    else:
	    legalize_with_dependencies(reg, field, field_yaml)

def parse_field(reg, field_name, field_yaml, len, real_len):
    global parsed_warl_fields
    global parsed_regs
    assign_str = ''
    get_str = ''
    if field_yaml['shadow'] is not None:
      if field_yaml['shadow_type'] == 'rw':
        shadow = field_yaml['shadow'].lower()
        if '.' in shadow:
          shadow_reg = shadow.split('.')[0]
          shadow_field = shadow.split('.')[1]
          if shadow_reg not in parsed_regs:
            print("please make reg %s before %s : %s\n"%(shadow_reg, reg, str(parsed_regs)))
            raise SystemExit
          if shadow in parsed_warl_fields:
            assign_str += '  %s = update_%s(%s, legalize_%s_%s(%s.%s(), v[%d .. %d]));\n'%(shadow_reg,
                        shadow_field.upper(), shadow_reg, shadow_reg, shadow_field.upper(), shadow_reg, shadow_field.upper(),
                        int(field_yaml['msb']), int(field_yaml['lsb']))
          else:
            assign_str += '  %s = update_%s(%s, v[%d .. %d]);\n'%(shadow_reg, shadow_field.upper(),
                            shadow_reg, int(field_yaml['msb']), int(field_yaml['lsb']))
          shadow = shadow_reg + '.' + shadow_field.upper() + '()'
        else:
          assign_str += '  %s = legalize_%s(%s, EXTZ(v[%d .. %d]));\n'%(shadow, shadow, shadow,
                          int(field_yaml['msb']), int(field_yaml['lsb']))

        if field_name == 'total':
          if len != real_len:
            assign_str += '  let m = %s @ 0b'%(shadow, len - 1, len - real_len) + \
                           ('0' *(len - real_len)) + ';\n'
            get_str = '  let m = %s @ 0b'%(shadow, len - 1, len - real_len) + ('0' *(len - real_len)) + ';\n'
          else:
            get_str += '  let m = %s;\n'%shadow
        else:
          get_str += '  let m = update_' + field_name.upper() + '(m, %s);\n'%shadow
        assign_str += get_str
      else:
        if field_name == 'total':
          assign_str += '  let m = o;\n'
        else:
          assign_str += '  let m = update_' + field_name.upper() + '(m, o.' + field_name.upper() + '());\n'
    elif 'ro_constant' in field_yaml['type']:
      ro_constant = field_yaml['type']['ro_constant']
      if 'x' in str(ro_constant):
        ro_constant = 'unsigned(' + ro_constant + ')'
      if field_name == 'total':
        if len != real_len:
          assign_str = '  let m = to_bits(%d, %s) @ 0b'%(real_len, str(ro_constant)) + \
                        ('0' *(len - real_len)) + ';\n'
        else:
          assign_str = '  let m : bits(%d) = EXTZ(0x%x);\n'%(len, ro_constant)
      else:
        assign_str = '  let m = update_' + field_name.upper() + '(m , to_bits(%d, %s));\n'%(len, str(ro_constant))
    elif 'ro_variable' in field_yaml['type']:
      if field_name == 'total':
        assign_str = '  let m = o;\n'
      else:
        assign_str = '  let m = update_' + field_name.upper() + '(m, o.' + field_name.upper() + '());\n'
    elif 'warl' in field_yaml['type']:
      parse_warl_value(reg, field_name, field_yaml)
      if field_name == 'total':
        parsed_warl_fields.append(reg.lower())
        if len != real_len:
          assign_str += '  let m = legalize_' + reg.lower() + '_' + field_name.upper() + \
                  '(o[%d .. %d] , v[%d .. %d]) @ 0b'%(len - 1, len-real_len, len - 1, len-real_len) + \
                  ('0' *(len - real_len)) + ';\n'
        else:
          assign_str += '  let m = legalize_' + reg.lower() + '_' + field_name.upper() + \
                    '(o[%d .. %d] , v[%d .. %d]);\n'%(len - 1, len-real_len, len - 1, len-real_len)
      else:
        parsed_warl_fields.append(reg.lower() + '.' + field_name.lower())
        assign_str = '  let m = update_' + field_name.upper() + '(m, legalize_' + reg.lower() + '_' + \
                       field_name.upper() + '(o.' + field_name.upper() + '()' + ', m.' + field_name.upper() + '()));\n'
    else:
      if field_name == 'total':
        if len != real_len:
          assign_str = '  let m = v[%d .. %d] @ 0b'%(len - 1, len - real_len) + ('0' *(len - real_len)) + ';\n'
        else:
          assign_str = '  let m = v[%d .. %d];\n'%(len - 1, 0)
    return (get_str, assign_str)

def parse_reg(reg, xlen, isa_yaml):
  global func_str
  global regs_str
  global reset_str
  global write_str
  global read_str
  reg_subfield_struct= '''
bitfield {0} : xlenbits = {{
{1}
}}
register {2} : {0}
'''
  reg_without_subfield_struct= '''
type {0} = bits({1})
register {2} : {0}
'''
  legalize_func= '''
function legalize_{0}(o : {1}, v : xlenbits) -> {1} = {{
  let m = Mk_{1}(v);
{2}  m
}}
'''
  legalize_func_without_subfield= '''
function legalize_{0}(o : {1}, v : xlenbits) -> {1} = {{
{2}  m
}}
'''

  get_func= '''
function get_{0}(o: {1}) -> {1} = {{
  let m = o;
{2}  m
}}
'''
  fields_str=''
  assign_field_strs = ''
  get_shadow_fields = ''
  if isa_yaml[reg]['rv' + xlen]['fields'] != []:   #reg with subfield
    for field in reversed(isa_yaml[reg]['rv' + xlen]):
      if field in isa_yaml[reg]['rv' + xlen]['fields']:
        if isa_yaml[reg]['rv' + xlen][field]['implemented']:
          len = int(isa_yaml[reg]['rv' + xlen][field]['msb']) - int(isa_yaml[reg]['rv' + xlen][field]['lsb']) + 1
          (get_str, assign_str) = parse_field(reg, field, isa_yaml[reg]['rv' + xlen][field], len, len)
          if get_str != '':
            fields_str += '/* shadow field of %s*/\n'%isa_yaml[reg]['rv' + xlen][field]['shadow']
          if isa_yaml[reg]['rv' + xlen][field]['msb'] != isa_yaml[reg]['rv' + xlen][field]['lsb']:
            fields_str += field.upper() + ' : ' + str(isa_yaml[reg]['rv' + xlen][field]['msb']) + ' .. ' \
                          + str(isa_yaml[reg]['rv' + xlen][field]['lsb']) + ',\n'
          else:
            fields_str += field.upper() + ' : ' + str(isa_yaml[reg]['rv' + xlen][field]['msb']) + ',\n'
          assign_field_strs += assign_str
          get_shadow_fields += get_str
    regs_str += reg_subfield_struct.format(reg.title(), fields_str[:-2], reg.lower())
    reset_str += '  %s->bits() = EXTZ(0x%x);\n'%(reg, isa_yaml[reg]['reset-val'])
    func_str += legalize_func.format(reg.lower(), reg.title(), assign_field_strs)
    if get_shadow_fields != '':
      func_str += get_func.format(reg.lower(), reg.title(), get_shadow_fields)
      read_str += '  0x%03x => { let m = get_%s(%s); Some(m.bits()) },\n'%(isa_yaml[reg]["address"], reg, reg)
    else:
      read_str += '  0x%03x => Some(%s.bits()),\n'%(isa_yaml[reg]['address'], reg)
    write_str += '  0x%03x => { %s = legalize_%s(%s, value); Some(%s.bits()) },\n'%(isa_yaml[reg]["address"], reg, reg, reg, reg)
  else: #reg without subfield
    real_len = int(isa_yaml[reg]['rv' + xlen]['msb']) - int(isa_yaml[reg]['rv' + xlen]['lsb']) + 1
    len = int(isa_yaml[reg]['rv' + xlen]['msb']) + 1
    regs_str += reg_without_subfield_struct.format(reg.title(), len, reg)
    if (int(isa_yaml[reg]['rv' + xlen]['msb']) % 4 != 0):
      reset_str += '  %s = to_bits(%d, unsigned(0x%x));\n'%(reg, len, isa_yaml[reg]['reset-val'])
    else:
      reset_str += '  %s = EXTZ(0x%x);\n'%(reg, isa_yaml[reg]['reset-val'])
    (get_str, assign_str) = parse_field(reg, 'total', isa_yaml[reg]['rv' + xlen], len, real_len)
    assign_field_strs += assign_str
    get_shadow_fields += get_str
    func_str += legalize_func_without_subfield.format(reg.lower(), 'bits(%d)'%len, assign_field_strs)
    if get_shadow_fields != '':
      func_str += get_func.format(reg.lower(), 'bits(%d)'%len, get_shadow_fields)
      if len != int(xlen):
        read_str += '  0x%03x => Some(EXTZ(get_%s(%s))),\n'%(isa_yaml[reg]['address'], reg, reg)
      else:
        read_str += '  0x%03x => Some(get_%s(%s)),\n'%(isa_yaml[reg]['address'], reg, reg)
    else:
      if len != int(xlen):
        read_str += '  0x%03x => Some(EXTZ(%s)),\n'%(isa_yaml[reg]['address'], reg)
      else:
        read_str += '  0x%03x => Some(%s),\n'%(isa_yaml[reg]['address'], reg)
    if len != int(xlen):
      write_str += '  0x%03x => { %s = legalize_%s(%s, value); Some(EXTZ(%s)) },\n'%(isa_yaml[reg]["address"], reg, reg, reg, reg)
    else:
      write_str += '  0x%03x => { %s = legalize_%s(%s, value); Some(%s) },\n'%(isa_yaml[reg]["address"], reg, reg, reg, reg)
  return

import getopt
import sys
arch = '64'
isa_yaml = 'generated_definitions/riscv-config/RV64/rv64i_isa_checked.yaml'
platform_yaml = 'generated_definitions/riscv-config/RV64/rv64i_platform_checked.yaml'
try:
    opts, args = getopt.getopt(sys.argv[1:], "a:i:p:",
                               ["arch= ", "isa_yaml=", "platform_yaml="])
    for k, v in opts:
        if k in ("-a", "--arch"):
            arch = v
        elif k in ("-i", "--isa_yaml"):
            isa_yaml = v
        elif k in ("-p", "--platform_yaml"):
            platform_yaml = v
except getopt.GetoptError:
    print('[getopt.GetoptError]')
    sys.exit()
if arch in ['32', '64']:
  isa_yaml = load_yaml(isa_yaml)['hart0']
  plat_yaml = load_yaml(platform_yaml)
  xlen = str(max(isa_yaml['supported_xlen']))
  parsed_warl_fields = []
  parsed_regs = []
  regs_str = ''
  func_str = warl_type_and_func
  reset_str = ''
  read_str = ''
  write_str = ''
  define_str = ''
  map_str = ''
  reset_func= '''
function reset_regs() -> unit = {{
{0}
}}
'''

  read_func= '''
function read_csr(csr : csreg) -> option(xlenbits) = {{
  let res : option(xlenbits) =
  match (csr) {{
{0}
  _     => None()
  }};
  res
}}
'''
  write_func= '''
function write_csr(csr : csreg, value : xlenbits) -> option(xlenbits) = {{
  let res : option(xlenbits) =
  match (csr) {{
{0}
  _     => None()
  }};
  res
}}
'''
  define_func= '''
function is_csr_defined (csr : csreg, p : Privilege) -> bool = match (csr) {{
{0}
  _     => false
}}
'''
  csr_map = '''
val csr_name_map : csreg <-> string

scattered mapping csr_name_map
{0}
/* trigger/debug */
mapping clause csr_name_map = 0x7a0  <-> "tselect"
mapping clause csr_name_map = 0x7a1  <-> "tdata1"
mapping clause csr_name_map = 0x7a2  <-> "tdata2"
mapping clause csr_name_map = 0x7a3  <-> "tdata3"
val csr_name : csreg -> string
overload to_str = {{csr_name}}
mapping clause csr_name_map = reg <-> hex_bits_12(reg)
end csr_name_map
/* XXX due to an apparent Sail bug the definition of this function must appear
   after the last csr_name_map clause and not by the val spec as it was
   previously. */
function csr_name(csr) = csr_name_map(csr)

'''
  for reg in isa_yaml:
      if reg not in ['custom_exceptions', 'custom_interrupts', 'ISA', 'supported_xlen', 'pmp_granularity', 'User_Spec_Version' , 'physical_addr_sz', 'Privilege_Spec_Version', 'hw_data_misaligned_support']:
          if isa_yaml[reg]['rv' + xlen]['accessible']:
            if reg not in ['mcycle', 'mcycleh', 'time', 'timeh', 'minstret', 'minstreth', 'cycle', 'cycleh', 'instret', 'instreth']:
              parse_reg(reg, xlen, isa_yaml)
              parsed_regs.append(reg)
            if isa_yaml[reg]['priv_mode'] == 'M':
              define_str += '  0x%03x => p == Machine,\n'%isa_yaml[reg]['address']
            elif isa_yaml[reg]['priv_mode'] == 'S':
              define_str += '  0x%03x => p == Machine | p == Supervisor,\n'%isa_yaml[reg]['address']
            else:
              define_str += '  0x%03x => true,\n'%isa_yaml[reg]['address']
            map_str += 'mapping clause csr_name_map = 0x%03x  <-> "%s"\n'%(isa_yaml[reg]['address'], reg)

  regs_str += csr_map.format(map_str)
  func_str += reset_func.format(reset_str[:-2])
  func_str += read_func.format(read_str)
  func_str += write_func.format(write_str)
  func_str += define_func.format(define_str)

  regsfile = open('generated_definitions/riscv-config/RV%s/riscv%s_regs_define.sail'%(arch, arch),'w')
  regsfile.write(regs_str)
  regsfile.close()
  funcsfile = open('generated_definitions/riscv-config/RV%s/riscv%s_regs_legalize.sail'%(arch, arch),'w')
  funcsfile.write(func_str)
  funcsfile.close()
