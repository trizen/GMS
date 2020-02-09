# GMS: Git Mathematical Sequences

An online resource of mathematical sequences, where anyone can contribute.

See also:

* GitHub: https://github.com/trizen/GMS

* GitBook: https://trizen.gitbooks.io/gms/

# How to submit a sequence?

Create a new directory with the username of your GitHub account and inside the directory create a new file called `Gx.md`, where `Gx` is the ID of the sequence.

The first ID of your sequence should be `G1`, the second ID should be `G2`, and so on.

### TEMPLATE

The sequence entry should have the following format:

```markdown
# (name of the sequence)

(terms)

## OFFSET

## COMMENTS

## PROPERTIES

## FORMULAS

## PROGRAMS

## SEE ALSO
```

### Template explained

````markdown
# (name of the sequence)

(the first few terms of the sequence)

## OFFSET

(offset n such that a(n) is the first term)
(use offset 1 if the sequence is a list of numbers)

## COMMENTS

(any comments about the sequence)

## PROPERTIES

(any special properties of the sequence (e.g. multiplicative))

## FORMULAS

(mathematical formulas for the n-th term)

## PROGRAMS

### (lang)

```lang-code
(program to generate the sequence)
```

## SEE ALSO

* (other similar sequences)
* (or external links to other resources about the sequence)
````

For some examples, see: [trizen/G1](trizen/G1.md), [trizen/G2](trizen/G2.md), [trizen/G3](trizen/G3.md).

After creating a sequence entry, send a pull request and wait for the sequence to be approved.

# License

All contributions are dedicated to the public domain.

See also: https://unlicense.org/
