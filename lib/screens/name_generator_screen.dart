import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Screen for generating character names
class NameGeneratorScreen extends StatefulWidget {
  const NameGeneratorScreen({super.key});

  @override
  State<NameGeneratorScreen> createState() => _NameGeneratorScreenState();
}

class _NameGeneratorScreenState extends State<NameGeneratorScreen> {
  final Random _random = Random();
  final List<GeneratedName> _generatedNames = [];
  final List<GeneratedName> _favoriteNames = [];

  // Filter options
  NameGender _selectedGender = NameGender.any;
  NameOrigin _selectedOrigin = NameOrigin.any;
  NameStyle _selectedStyle = NameStyle.any;
  bool _includeMiddleName = false;
  bool _includeLastName = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Name Generator'),
        actions: [
          if (_favoriteNames.isNotEmpty)
            Badge(
              label: Text(_favoriteNames.length.toString()),
              child: IconButton(
                icon: const Icon(Icons.favorite),
                onPressed: _showFavorites,
                tooltip: 'Favorites',
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),

          // Generate button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _generateNames,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Generate Names'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _clearNames,
                  icon: const Icon(Icons.clear_all),
                  tooltip: 'Clear All',
                ),
              ],
            ),
          ),

          // Generated names list
          Expanded(
            child: _generatedNames.isEmpty
                ? _buildEmptyState()
                : _buildNamesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Gender and Origin
          Row(
            children: [
              Expanded(
                child: _buildDropdown<NameGender>(
                  label: 'Gender',
                  value: _selectedGender,
                  items: NameGender.values,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                  itemLabel: (item) => item.displayName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown<NameOrigin>(
                  label: 'Origin',
                  value: _selectedOrigin,
                  items: NameOrigin.values,
                  onChanged: (value) {
                    setState(() {
                      _selectedOrigin = value!;
                    });
                  },
                  itemLabel: (item) => item.displayName,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Second row: Style and checkboxes
          Row(
            children: [
              Expanded(
                child: _buildDropdown<NameStyle>(
                  label: 'Style',
                  value: _selectedStyle,
                  items: NameStyle.values,
                  onChanged: (value) {
                    setState(() {
                      _selectedStyle = value!;
                    });
                  },
                  itemLabel: (item) => item.displayName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _includeMiddleName,
                      onChanged: (value) {
                        setState(() {
                          _includeMiddleName = value!;
                        });
                      },
                    ),
                    const Text('Middle'),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: _includeLastName,
                      onChanged: (value) {
                        setState(() {
                          _includeLastName = value!;
                        });
                      },
                    ),
                    const Text('Last'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Generate character names',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the filters above to customize your search',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNamesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _generatedNames.length,
      itemBuilder: (context, index) {
        final name = _generatedNames[index];
        final isFavorite = _favoriteNames.contains(name);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getGenderColor(name.gender),
              child: Text(
                name.firstName[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              name.fullName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${name.gender.displayName} • ${name.origin.displayName}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isFavorite) {
                        _favoriteNames.remove(name);
                      } else {
                        _favoriteNames.add(name);
                      }
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyToClipboard(name.fullName),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _generateNames() {
    setState(() {
      _generatedNames.clear();
      for (int i = 0; i < 10; i++) {
        _generatedNames.add(_generateSingleName());
      }
    });
  }

  GeneratedName _generateSingleName() {
    // Determine gender
    final gender = _selectedGender == NameGender.any
        ? (_random.nextBool() ? NameGender.male : NameGender.female)
        : _selectedGender;

    // Determine origin
    final origin = _selectedOrigin == NameOrigin.any
        ? NameOrigin.values[_random.nextInt(NameOrigin.values.length - 1) + 1]
        : _selectedOrigin;

    // Get name lists based on origin and gender
    final firstNames = _getFirstNames(gender, origin);
    final middleNames = _getFirstNames(gender, origin);
    final lastNames = _getLastNames(origin);

    // Generate the name
    final firstName = firstNames[_random.nextInt(firstNames.length)];
    final middleName = _includeMiddleName
        ? middleNames[_random.nextInt(middleNames.length)]
        : null;
    final lastName = _includeLastName
        ? lastNames[_random.nextInt(lastNames.length)]
        : null;

    return GeneratedName(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      gender: gender,
      origin: origin,
    );
  }

  List<String> _getFirstNames(NameGender gender, NameOrigin origin) {
    // Comprehensive name database
    final names = <NameOrigin, Map<NameGender, List<String>>>{
      NameOrigin.english: {
        NameGender.male: [
          'James', 'William', 'Henry', 'Charles', 'George', 'Edward', 'Thomas',
          'Richard', 'Robert', 'John', 'Michael', 'David', 'Daniel', 'Matthew',
          'Christopher', 'Andrew', 'Benjamin', 'Samuel', 'Joseph', 'Alexander',
          'Oliver', 'Jack', 'Harry', 'Leo', 'Oscar', 'Archie', 'Arthur', 'Noah',
        ],
        NameGender.female: [
          'Elizabeth', 'Victoria', 'Charlotte', 'Emma', 'Olivia', 'Sophia',
          'Isabella', 'Amelia', 'Emily', 'Grace', 'Alice', 'Eleanor', 'Rose',
          'Catherine', 'Margaret', 'Anne', 'Mary', 'Sarah', 'Jane', 'Lucy',
          'Lily', 'Ivy', 'Ruby', 'Violet', 'Clara', 'Florence', 'Evelyn', 'Ada',
        ],
      },
      NameOrigin.spanish: {
        NameGender.male: [
          'Carlos', 'Miguel', 'Diego', 'Alejandro', 'Fernando', 'Rafael',
          'Antonio', 'José', 'Luis', 'Manuel', 'Pedro', 'Francisco', 'Javier',
          'Pablo', 'Sergio', 'Andrés', 'Ricardo', 'Enrique', 'Gabriel', 'Mateo',
        ],
        NameGender.female: [
          'María', 'Sofia', 'Isabella', 'Valentina', 'Camila', 'Lucia', 'Elena',
          'Carmen', 'Rosa', 'Ana', 'Laura', 'Patricia', 'Gabriela', 'Adriana',
          'Catalina', 'Natalia', 'Daniela', 'Mariana', 'Victoria', 'Alejandra',
        ],
      },
      NameOrigin.french: {
        NameGender.male: [
          'Jean', 'Pierre', 'Louis', 'Henri', 'François', 'Jacques', 'Philippe',
          'Michel', 'Claude', 'André', 'René', 'Marcel', 'Étienne', 'Olivier',
          'Laurent', 'Théo', 'Lucas', 'Hugo', 'Léon', 'Gabriel',
        ],
        NameGender.female: [
          'Marie', 'Sophie', 'Isabelle', 'Camille', 'Claire', 'Marguerite',
          'Élise', 'Charlotte', 'Amélie', 'Juliette', 'Adèle', 'Léa', 'Emma',
          'Louise', 'Manon', 'Chloé', 'Inès', 'Jade', 'Zoé', 'Alice',
        ],
      },
      NameOrigin.german: {
        NameGender.male: [
          'Hans', 'Friedrich', 'Wilhelm', 'Heinrich', 'Karl', 'Otto', 'Ludwig',
          'Wolfgang', 'Klaus', 'Dieter', 'Günther', 'Helmut', 'Werner', 'Rolf',
          'Maximilian', 'Felix', 'Leon', 'Paul', 'Lukas', 'Finn',
        ],
        NameGender.female: [
          'Anna', 'Maria', 'Elisabeth', 'Margarete', 'Katharina', 'Sophie',
          'Hannah', 'Emma', 'Mia', 'Lena', 'Laura', 'Lea', 'Julia', 'Lisa',
          'Frieda', 'Greta', 'Helene', 'Clara', 'Amelie', 'Charlotte',
        ],
      },
      NameOrigin.italian: {
        NameGender.male: [
          'Marco', 'Giuseppe', 'Giovanni', 'Francesco', 'Antonio', 'Alessandro',
          'Andrea', 'Luca', 'Matteo', 'Lorenzo', 'Riccardo', 'Davide', 'Stefano',
          'Federico', 'Leonardo', 'Gabriele', 'Tommaso', 'Simone', 'Pietro', 'Nicola',
        ],
        NameGender.female: [
          'Maria', 'Anna', 'Giulia', 'Francesca', 'Sofia', 'Sara', 'Valentina',
          'Chiara', 'Alessandra', 'Martina', 'Elena', 'Lucia', 'Giorgia',
          'Beatrice', 'Aurora', 'Alice', 'Emma', 'Ginevra', 'Viola', 'Bianca',
        ],
      },
      NameOrigin.irish: {
        NameGender.male: [
          'Liam', 'Sean', 'Conor', 'Patrick', 'Aidan', 'Declan', 'Cillian',
          'Finn', 'Oisín', 'Cian', 'Darragh', 'Ronan', 'Eoin', 'Niall', 'Colm',
          'Cathal', 'Brendan', 'Shane', 'Brian', 'Killian',
        ],
        NameGender.female: [
          'Aoife', 'Siobhan', 'Ciara', 'Niamh', 'Saoirse', 'Aisling', 'Caoimhe',
          'Róisín', 'Orla', 'Fiona', 'Maeve', 'Sinead', 'Eileen', 'Bridget',
          'Grainne', 'Clodagh', 'Erin', 'Shannon', 'Kerry', 'Deirdre',
        ],
      },
      NameOrigin.scottish: {
        NameGender.male: [
          'Angus', 'Malcolm', 'Duncan', 'Hamish', 'Alistair', 'Callum', 'Fraser',
          'Lachlan', 'Campbell', 'Douglas', 'Graham', 'Bruce', 'Ross', 'Craig',
          'Gordon', 'Murray', 'Stuart', 'Cameron', 'Finlay', 'Blair',
        ],
        NameGender.female: [
          'Isla', 'Ailsa', 'Morag', 'Eilidh', 'Fiona', 'Kirsty', 'Heather',
          'Elspeth', 'Mhairi', 'Catriona', 'Iona', 'Skye', 'Bonnie', 'Flora',
          'Morven', 'Sorcha', 'Blair', 'Ainsley', 'Lorna', 'Jean',
        ],
      },
      NameOrigin.nordic: {
        NameGender.male: [
          'Erik', 'Lars', 'Sven', 'Magnus', 'Bjorn', 'Olaf', 'Harald', 'Leif',
          'Thor', 'Ragnar', 'Ivar', 'Gunnar', 'Sigurd', 'Axel', 'Oscar',
          'Emil', 'Nils', 'Anders', 'Henrik', 'Johan',
        ],
        NameGender.female: [
          'Astrid', 'Freya', 'Ingrid', 'Sigrid', 'Helga', 'Greta', 'Saga',
          'Liv', 'Elsa', 'Maja', 'Linnea', 'Ebba', 'Wilma', 'Alva', 'Elin',
          'Ida', 'Signe', 'Thyra', 'Solveig', 'Ylva',
        ],
      },
      NameOrigin.greek: {
        NameGender.male: [
          'Alexander', 'Nicholas', 'Theodore', 'Constantine', 'Dimitri',
          'Andreas', 'Stavros', 'Nikos', 'Petros', 'Georgios', 'Spiros',
          'Christos', 'Yannis', 'Kostas', 'Alexandros', 'Leonidas', 'Stefanos',
          'Vasilis', 'Michalis', 'Panagiotis',
        ],
        NameGender.female: [
          'Sophia', 'Alexandra', 'Athena', 'Helena', 'Penelope', 'Cassandra',
          'Daphne', 'Chloe', 'Irene', 'Thea', 'Zoe', 'Calliope', 'Ariadne',
          'Eleni', 'Maria', 'Georgia', 'Katerina', 'Christina', 'Dimitra', 'Anna',
        ],
      },
      NameOrigin.slavic: {
        NameGender.male: [
          'Ivan', 'Dmitri', 'Alexei', 'Nikolai', 'Sergei', 'Mikhail', 'Andrei',
          'Vladimir', 'Boris', 'Fyodor', 'Yuri', 'Pavel', 'Viktor', 'Oleg',
          'Maxim', 'Artem', 'Roman', 'Kirill', 'Stanislav', 'Bogdan',
        ],
        NameGender.female: [
          'Natasha', 'Anastasia', 'Katya', 'Olga', 'Svetlana', 'Irina', 'Tatiana',
          'Marina', 'Elena', 'Anya', 'Sasha', 'Mila', 'Vera', 'Nina', 'Daria',
          'Yelena', 'Lyudmila', 'Valentina', 'Nadia', 'Sonya',
        ],
      },
      NameOrigin.japanese: {
        NameGender.male: [
          'Hiroshi', 'Takeshi', 'Kenji', 'Yuki', 'Haruki', 'Ryu', 'Akira',
          'Koji', 'Taro', 'Masashi', 'Kazuki', 'Ren', 'Sota', 'Kaito', 'Yuto',
          'Haruto', 'Hinata', 'Shota', 'Daiki', 'Kenta',
        ],
        NameGender.female: [
          'Yuki', 'Sakura', 'Hana', 'Aiko', 'Mei', 'Rin', 'Yui', 'Akiko',
          'Haruka', 'Mio', 'Nanami', 'Kokoro', 'Miyu', 'Saki', 'Nana',
          'Himari', 'Ichika', 'Riko', 'Ayaka', 'Misaki',
        ],
      },
      NameOrigin.chinese: {
        NameGender.male: [
          'Wei', 'Ming', 'Jun', 'Lei', 'Chen', 'Feng', 'Hao', 'Long', 'Qiang',
          'Tao', 'Xing', 'Yang', 'Zhen', 'Bo', 'Gang', 'Jian', 'Lin', 'Ping',
          'Wen', 'Yi',
        ],
        NameGender.female: [
          'Mei', 'Li', 'Xiu', 'Ying', 'Lan', 'Jing', 'Fang', 'Hua', 'Qing',
          'Yan', 'Xia', 'Juan', 'Hong', 'Yu', 'Ling', 'Ning', 'Shu', 'Ting',
          'Wei', 'Yun',
        ],
      },
      NameOrigin.arabic: {
        NameGender.male: [
          'Ahmed', 'Mohammed', 'Ali', 'Omar', 'Hassan', 'Khalid', 'Ibrahim',
          'Yusuf', 'Karim', 'Tariq', 'Amir', 'Rashid', 'Farid', 'Nasser',
          'Samir', 'Jamal', 'Hamza', 'Malik', 'Zayd', 'Adam',
        ],
        NameGender.female: [
          'Fatima', 'Aisha', 'Layla', 'Noor', 'Sara', 'Yasmin', 'Amira', 'Hana',
          'Mariam', 'Leila', 'Zahra', 'Salma', 'Dina', 'Rania', 'Sana', 'Huda',
          'Nadine', 'Lina', 'Maya', 'Dana',
        ],
      },
      NameOrigin.indian: {
        NameGender.male: [
          'Raj', 'Arjun', 'Vikram', 'Arun', 'Rohan', 'Dev', 'Kiran', 'Sanjay',
          'Amit', 'Rahul', 'Nikhil', 'Aditya', 'Vivek', 'Suresh', 'Pradeep',
          'Krishna', 'Ravi', 'Ashok', 'Deepak', 'Ajay',
        ],
        NameGender.female: [
          'Priya', 'Ananya', 'Devi', 'Lakshmi', 'Maya', 'Asha', 'Sunita', 'Neha',
          'Kavita', 'Pooja', 'Anjali', 'Divya', 'Shreya', 'Meera', 'Riya',
          'Aishwarya', 'Sita', 'Radha', 'Nisha', 'Geeta',
        ],
      },
      NameOrigin.african: {
        NameGender.male: [
          'Kwame', 'Kofi', 'Amadi', 'Chidi', 'Emeka', 'Jabari', 'Malik', 'Olu',
          'Sekou', 'Tendai', 'Zuberi', 'Azizi', 'Bakari', 'Dakarai', 'Faraji',
          'Jelani', 'Kamau', 'Mandla', 'Nnamdi', 'Oluwaseun',
        ],
        NameGender.female: [
          'Amara', 'Adaeze', 'Chioma', 'Eshe', 'Fatou', 'Imani', 'Jamila',
          'Kali', 'Lulu', 'Makena', 'Nia', 'Oluchi', 'Sanaa', 'Thandiwe',
          'Uzoma', 'Wanjiku', 'Yaa', 'Zara', 'Aminata', 'Binta',
        ],
      },
    };

    // Default fallback for 'any' origin
    if (!names.containsKey(origin)) {
      return names[NameOrigin.english]![gender]!;
    }

    return names[origin]![gender]!;
  }

  List<String> _getLastNames(NameOrigin origin) {
    final lastNames = <NameOrigin, List<String>>{
      NameOrigin.english: [
        'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Miller', 'Davis',
        'Wilson', 'Moore', 'Taylor', 'Anderson', 'Thomas', 'Jackson', 'White',
        'Harris', 'Martin', 'Thompson', 'Garcia', 'Martinez', 'Robinson',
        'Clark', 'Rodriguez', 'Lewis', 'Lee', 'Walker', 'Hall', 'Allen', 'Young',
      ],
      NameOrigin.spanish: [
        'García', 'Rodríguez', 'Martínez', 'López', 'González', 'Hernández',
        'Pérez', 'Sánchez', 'Ramírez', 'Torres', 'Flores', 'Rivera', 'Gómez',
        'Díaz', 'Cruz', 'Morales', 'Reyes', 'Ortiz', 'Gutiérrez', 'Vargas',
      ],
      NameOrigin.french: [
        'Martin', 'Bernard', 'Dubois', 'Thomas', 'Robert', 'Richard', 'Petit',
        'Durand', 'Leroy', 'Moreau', 'Simon', 'Laurent', 'Lefebvre', 'Michel',
        'Garcia', 'David', 'Bertrand', 'Roux', 'Vincent', 'Fournier',
      ],
      NameOrigin.german: [
        'Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Wagner',
        'Becker', 'Schulz', 'Hoffmann', 'Schäfer', 'Koch', 'Bauer', 'Richter',
        'Klein', 'Wolf', 'Schröder', 'Neumann', 'Schwarz', 'Zimmermann',
      ],
      NameOrigin.italian: [
        'Rossi', 'Russo', 'Ferrari', 'Esposito', 'Bianchi', 'Romano', 'Colombo',
        'Ricci', 'Marino', 'Greco', 'Bruno', 'Gallo', 'Conti', 'De Luca',
        'Mancini', 'Costa', 'Giordano', 'Rizzo', 'Lombardi', 'Moretti',
      ],
      NameOrigin.irish: [
        "O'Brien", "O'Connor", "O'Sullivan", "O'Neill", "Murphy", 'Kelly',
        'Walsh', 'Ryan', 'Byrne', 'Doyle', 'McCarthy', 'Fitzgerald', 'Brennan',
        'Gallagher', 'Quinn', 'Doherty', 'Kennedy', 'Lynch', 'Murray', 'Burke',
      ],
      NameOrigin.scottish: [
        'Campbell', 'MacDonald', 'Stewart', 'MacLeod', 'Robertson', 'Ross',
        'MacKenzie', 'Fraser', 'MacLean', 'Murray', 'Cameron', 'Henderson',
        'Hamilton', 'Graham', 'Sinclair', 'Ferguson', 'Douglas', 'Gordon',
        'Wallace', 'Duncan',
      ],
      NameOrigin.nordic: [
        'Andersson', 'Johansson', 'Karlsson', 'Nilsson', 'Eriksson', 'Larsson',
        'Olsson', 'Persson', 'Svensson', 'Gustafsson', 'Pettersson', 'Jonsson',
        'Jansson', 'Hansson', 'Bengtsson', 'Lindberg', 'Lindqvist', 'Lindgren',
        'Berg', 'Bergström',
      ],
      NameOrigin.greek: [
        'Papadopoulos', 'Georgiou', 'Nikolaou', 'Dimitriou', 'Konstantinou',
        'Pappas', 'Alexiou', 'Antoniou', 'Christodoulou', 'Economou', 'Karagiannis',
        'Makris', 'Papageorgiou', 'Stavrou', 'Theodorou', 'Vasileiou',
      ],
      NameOrigin.slavic: [
        'Ivanov', 'Petrov', 'Sidorov', 'Smirnov', 'Kuznetsov', 'Popov', 'Vasiliev',
        'Sokolov', 'Mikhailov', 'Fedorov', 'Morozov', 'Volkov', 'Alexeev',
        'Lebedev', 'Kozlov', 'Novikov', 'Morozov', 'Pavlov', 'Egorov', 'Orlov',
      ],
      NameOrigin.japanese: [
        'Sato', 'Suzuki', 'Takahashi', 'Tanaka', 'Watanabe', 'Ito', 'Yamamoto',
        'Nakamura', 'Kobayashi', 'Kato', 'Yoshida', 'Yamada', 'Sasaki', 'Yamaguchi',
        'Matsumoto', 'Inoue', 'Kimura', 'Hayashi', 'Shimizu', 'Yamazaki',
      ],
      NameOrigin.chinese: [
        'Wang', 'Li', 'Zhang', 'Liu', 'Chen', 'Yang', 'Huang', 'Zhao', 'Wu', 'Zhou',
        'Xu', 'Sun', 'Ma', 'Zhu', 'Hu', 'Guo', 'Lin', 'He', 'Gao', 'Luo',
      ],
      NameOrigin.arabic: [
        'Al-Hassan', 'Al-Rashid', 'Ibrahim', 'Ahmed', 'Mohammed', 'Abdullah',
        'Al-Farsi', 'Al-Khalil', 'Al-Mansour', 'Nasser', 'Salim', 'Mahmoud',
        'Farouk', 'Hamid', 'Kareem', 'Rahman', 'Sharif', 'Youssef', 'Zayed', 'Omar',
      ],
      NameOrigin.indian: [
        'Patel', 'Sharma', 'Singh', 'Kumar', 'Gupta', 'Shah', 'Reddy', 'Rao',
        'Nair', 'Mehta', 'Desai', 'Joshi', 'Verma', 'Iyer', 'Malhotra', 'Agarwal',
        'Bose', 'Chatterjee', 'Mukherjee', 'Banerjee',
      ],
      NameOrigin.african: [
        'Mensah', 'Okonkwo', 'Ndlovu', 'Mbeki', 'Diallo', 'Kamara', 'Osei',
        'Adeyemi', 'Okafor', 'Ngozi', 'Banda', 'Asante', 'Chukwu', 'Dlamini',
        'Eze', 'Folarin', 'Gyasi', 'Igwe', 'Jakande', 'Keita',
      ],
    };

    // Default fallback
    if (!lastNames.containsKey(origin)) {
      return lastNames[NameOrigin.english]!;
    }

    return lastNames[origin]!;
  }

  Color _getGenderColor(NameGender gender) {
    switch (gender) {
      case NameGender.male:
        return Colors.blue;
      case NameGender.female:
        return Colors.pink;
      case NameGender.any:
        return Colors.purple;
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$text" to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearNames() {
    setState(() {
      _generatedNames.clear();
    });
  }

  void _showFavorites() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red),
                    const SizedBox(width: 8),
                    const Text(
                      'Favorite Names',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        // Copy all favorites
                        final allNames = _favoriteNames
                            .map((n) => n.fullName)
                            .join('\n');
                        Clipboard.setData(ClipboardData(text: allNames));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('All favorites copied to clipboard'),
                          ),
                        );
                      },
                      child: const Text('Copy All'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _favoriteNames.length,
                  itemBuilder: (context, index) {
                    final name = _favoriteNames[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getGenderColor(name.gender),
                        child: Text(
                          name.firstName[0],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(name.fullName),
                      subtitle: Text(name.origin.displayName),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _favoriteNames.removeAt(index);
                          });
                          Navigator.pop(context);
                          if (_favoriteNames.isNotEmpty) {
                            _showFavorites();
                          }
                        },
                      ),
                      onTap: () => _copyToClipboard(name.fullName),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Represents a generated name
class GeneratedName {
  final String firstName;
  final String? middleName;
  final String? lastName;
  final NameGender gender;
  final NameOrigin origin;

  const GeneratedName({
    required this.firstName,
    this.middleName,
    this.lastName,
    required this.gender,
    required this.origin,
  });

  String get fullName {
    final parts = <String>[firstName];
    if (middleName != null) parts.add(middleName!);
    if (lastName != null) parts.add(lastName!);
    return parts.join(' ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeneratedName && other.fullName == fullName;
  }

  @override
  int get hashCode => fullName.hashCode;
}

/// Gender options for name generation
enum NameGender {
  any('Any'),
  male('Male'),
  female('Female');

  final String displayName;
  const NameGender(this.displayName);
}

/// Origin/culture options for name generation
enum NameOrigin {
  any('Any'),
  english('English'),
  spanish('Spanish'),
  french('French'),
  german('German'),
  italian('Italian'),
  irish('Irish'),
  scottish('Scottish'),
  nordic('Nordic'),
  greek('Greek'),
  slavic('Slavic'),
  japanese('Japanese'),
  chinese('Chinese'),
  arabic('Arabic'),
  indian('Indian'),
  african('African');

  final String displayName;
  const NameOrigin(this.displayName);
}

/// Style options for name generation
enum NameStyle {
  any('Any'),
  classic('Classic'),
  modern('Modern'),
  fantasy('Fantasy'),
  historical('Historical');

  final String displayName;
  const NameStyle(this.displayName);
}
